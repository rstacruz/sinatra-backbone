require File.expand_path('../test_helper', __FILE__)

DB.create_table :albums do
  primary_key :id
  String :title
  String :artist
end

class Album < Sequel::Model
  def to_json
    "X"
  end

  def to_hash
    { :name => name, :author => author }
  end

  def to_xml
    "lol"
  end
end

class ToJsonTest < UnitTest
  class App < Sinatra::Base
    register Sinatra::RestAPI
    disable :show_exceptions
    enable :raise_errors
    rest_resource("/album/:id") { |id| Album[id] }
  end
  def app() App; end

  setup do
    @album = Album.new
    @album.title  = "Tanto Tempo"
    @album.artist = "Bebel Gilberto"
    @album.save
    header 'Accept', 'application/json, */*'
  end

  test "use to_json" do
    get "/album/#{@album.id}"
    assert last_response.body == @album.to_json
  end
end
