$:.unshift File.expand_path('../../lib', __FILE__)

require 'sinatra/base'
require 'sequel'
require 'sinatra/backbone'

DB = Sequel.connect("sqlite::memory:")
DB.create_table :books do
  primary_key :id
  String :title
  String :author
end

class Book < Sequel::Model
  def to_hash
    { :id => id, :title => title, :author => author }
  end

  def validate
    errors.add :author, "can't be empty"  if author.to_s.size == 0
  end
end

class App < Sinatra::Base
  enable   :raise_errors, :logging
  enable   :show_exceptions  if development?

  register Sinatra::RestAPI

  rest_create("/book") { Book.new }
  rest_resource("/book/:id") { |id| Book[id] }

  set :root,   File.expand_path('../', __FILE__)
  set :views,  File.expand_path('../', __FILE__)
  set :public, File.expand_path('../public', __FILE__)

  get '/' do
    erb :home
  end
end
