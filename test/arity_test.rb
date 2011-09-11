require File.expand_path('../test_helper', __FILE__)

class ArityTest < UnitTest
  class FauxModel
    def initialize(stuff)
      @stuff = stuff
    end

    def to_hash
      { :contents => @stuff }
    end
  end

  class App < Sinatra::Base
    register Sinatra::RestAPI
    disable :show_exceptions
    enable :raise_errors

    rest_resource("/api/:x/:y/:z") { |x, y, z| FauxModel.new ["Hello", x.to_i+1, y.to_i+1, z.to_i+1] }
  end

  def app() App; end

  describe "Multi args support" do
    test "get" do
      header 'Accept', 'application/json, */*'
      get "/api/20/40/60"

      assert json_response["contents"] = ["Hello", 21, 41, 61]
    end

    test "put/post" do
      FauxModel.any_instance.expects(:x=).times(1).returns(true)
      FauxModel.any_instance.expects(:save).times(1).returns(true)

      header 'Accept', 'application/json, */*'
      header 'Content-Type', 'application/json'
      post "/api/20/40/60", JSON.generate('x' => 2)

      assert json_response["contents"] = ["Hello", 21, 41, 61]
    end
  end
end
