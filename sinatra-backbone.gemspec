require './lib/sinatra/backbone'
Gem::Specification.new do |s|
  s.name = "sinatra-backbone"
  s.version = Sinatra::Backbone.version
  s.summary = "Helpful stuff using Sinatra with Backbone."
  s.description = "Provides Rest API access to your models and serves JST pages."
  s.authors = ["Rico Sta. Cruz"]
  s.email = ["rico@sinefunc.com"]
  s.homepage = "http://github.com/rstacruz/sinatra-backbone"
  s.files = `git ls-files`.strip.split("\n")
  s.executables = Dir["bin/*"].map { |f| File.basename(f) }

  s.add_dependency "sinatra"
  s.add_development_dependency "sequel", ">= 3.25.0"
  s.add_development_dependency "sqlite3", ">= 1.3.4"
  s.add_development_dependency "contest"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rack-test"
end
