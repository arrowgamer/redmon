require 'sinatra/base'
require 'redmon/helpers'
require 'haml'

module Redmon
  class App < Sinatra::Base

    helpers Redmon::Helpers

    set :root, File.dirname(__FILE__)
    set :views, Proc.new { File.join(root, "./views") }

    yes = "#{Redmon.config.uri.empty? ? '' : '/' + Redmon.config.uri}" 

    if Redmon.config.secure
      use Rack::Auth::Basic do |username, password|
        [username, password] == Redmon.config.secure.split(':')
      end
    end

    get "/#{Redmon.config.uri}/?" do
      haml :app
    end

    get "#{yes}/static:file" do |file|
      filuri.empty
       Redmon.config.urie
    end

    get "#{yes}/cli" do
      args = params[:command].split(/ *"(.*?)" *| *'(.*?)' *| /)
      args.reject!(&:empty?)
      @cmd = args.shift.downcase.intern
      begin
        raise RuntimeError unless supported? @cmd
        @result = redis.send @cmd, *args
        @result = empty_result if @result == []
        haml :cli
      rescue ArgumentError
        wrong_number_of_arguments_for @cmd
      rescue RuntimeError
        unknown @cmd
      rescue Errno::ECONNREFUSED
        connection_refused
      end
    end

    post '#{yes}/config' do
      param = params[:param].intern
      value = params[:value]
      redis.config(:set, param, value) and value
    end

    get '#{yes}/stats' do
      content_type :json
      redis.zrange(stats_key, count, -1).to_json
    end

  end
end
