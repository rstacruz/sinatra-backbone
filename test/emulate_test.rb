require File.expand_path('../test_helper', __FILE__)
require 'ostruct'

class EmulateTest < UnitTest
  class App < Sinatra::Base
    register Sinatra::RestAPI
    disable :show_exceptions
    enable :raise_errors

    rest_resource("/api/:id") { |id| FauxModel.new }
    put "/firefox/:id" do
      rest_params.to_json
    end
  end

  def app() App; end

  setup do
    header 'Accept', 'application/json, */*'
  end

  test "emulate json and emulate http" do
    FauxModel.any_instance.expects(:two=).times(1).returns(true)
    FauxModel.any_instance.expects(:save).times(1).returns(true)
    FauxModel.any_instance.expects(:valid?).times(1).returns(true)
    FauxModel.any_instance.expects(:to_hash).times(1).returns('a' => 'b')

    post "/api/2", :model => { :two => 2 }.to_json
    assert json_response == { 'a' => 'b' }
  end

  test "parse rest_params properly with charset encoding included within content_type" do
    put "/firefox/2", :model => { :one => 1 }.to_json, :content_type => "application/json"
    assert json_response == {"one" => 1}

    put "/firefox/2", :model => { :two => 2 }.to_json, :content_type => "application/json; charset=UTF-8"
    assert json_response == {"two" => 2}
  end
end

class FauxModel
end

