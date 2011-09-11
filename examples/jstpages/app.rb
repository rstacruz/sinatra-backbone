$:.unshift File.expand_path('../../../lib', __FILE__)

require 'sinatra/base'
require 'sequel'
require 'sinatra/backbone'

class App < Sinatra::Base
  enable   :raise_errors, :logging
  enable   :show_exceptions  if development?

  register Sinatra::JstPages
  serve_jst '/jst.js'

  set :root,   File.expand_path('../', __FILE__)
  set :views,  File.expand_path('../views', __FILE__)
  set :public, File.expand_path('../public', __FILE__)

  get '/' do
    erb :home
  end
end
