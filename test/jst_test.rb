require File.expand_path('../test_helper', __FILE__)

class JstTest < UnitTest
  class App < Sinatra::Base
    register Sinatra::JstPages
    disable :show_exceptions
    enable :raise_errors

    set :views, File.expand_path('../app/views', __FILE__)
    serve_jst '/jst.js'
  end
  def app() App; end

  test "jst" do
    get '/jst.js'
    body = last_response.body

    assert body.include? 'window.JST'

    assert body.include? '["editor/edit"]'
    assert body.include? "Hello"

    assert body.include? '["chrome"]'
    assert body.include? "chrome"
  end
end
