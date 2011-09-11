$:.unshift File.expand_path('../../lib', __FILE__)
require 'contest'
require 'mocha'
require 'sinatra/base'
require 'sequel'
require 'rack/test'
require 'json'
require 'sinatra/backbone'

class UnitTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def json_response
    JSON.parse last_response.body
  end
end

DB = Sequel.connect('sqlite::memory:')
