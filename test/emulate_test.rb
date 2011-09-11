require File.expand_path('../test_helper', __FILE__)

class EmulateTest < UnitTest
  class App < Sinatra::Base
    register Sinatra::RestAPI
    disable :show_exceptions
    enable :raise_errors

    rest_resource("/api/:id") { |id| FauxModel.new id }
  end

  def app() App; end

  setup do
    header 'Accept', 'application/json, */*'
  end

  test "emulate json and emulate http" do
    FauxModel.any_instance.expects(:two=).times(1).returns(true)
    FauxModel.any_instance.expects(:save).times(1).returns(true)
    FauxModel.any_instance.expects(:to_hash).times(1).returns('a' => 'b')

    post "/api/2", :model => { :two => 2 }.to_json
    assert json_response == { 'a' => 'b' }
  end
end

class FauxModel
end

