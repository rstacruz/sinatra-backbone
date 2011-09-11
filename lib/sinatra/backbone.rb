module Sinatra
  module Backbone
    def self.version
      "0.1.0.rc2"
    end
  end

  autoload :RestAPI,  "sinatra/restapi"
  autoload :JstPages, "sinatra/jstpages"
end
