require File.expand_path('../test_helper', __FILE__)

DB.create_table :books do
  primary_key :id
  String :name
  String :author
end

class Book < Sequel::Model
  def to_hash
    { :name => name, :author => author }
  end

  def validate
    super
    errors.add(:author, "can't be empty")  if author.to_s.size == 0
  end
end

class AppTest < UnitTest
  class App < Sinatra::Base
    register Sinatra::RestAPI
    disable :show_exceptions
    enable :raise_errors
    rest_create("/book") { Book.new }
    rest_resource("/book/:id") { |id| Book[id] }
  end
  def app() App; end

  describe "Sinatra::RestAPI" do
    setup do
      @book = Book.new
      @book.name   = "Darkly Dreaming Dexter"
      @book.author = "Jeff Lindsay"
      @book.save
      header 'Accept', 'application/json, */*'
    end

    teardown do
      @book.destroy  if Book[@book.id]
    end

    test "should work properly" do
      get "/book/#{@book.id}"

      assert json_response['name']   == @book.name
      assert json_response['author'] == @book.author
    end

    test "validation fail" do
      hash = { :name => "The Claiming of Sleeping Beauty" }
      post "/book", :model => hash.to_json
      p last_response
    end

    test "should 404" do
      get "/book/823978"

      assert last_response.status == 404
    end
  end
end
