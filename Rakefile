desc "Invokes the test suite in multiple RVM environments"
task :'test!' do
  # Override this by adding RVM_TEST_ENVS=".." in .rvmrc
  envs = ENV['RVM_TEST_ENVS'] || '1.9.2@sinatra,1.8.7@sinatra'
  puts "* Testing in the following RVM environments: #{envs.gsub(',', ', ')}"
  system "rvm #{envs} rake test" or abort
end

desc "Runs tests"
task :test do
  Dir['test/*_test.rb'].each { |f| load f }
end

task :default => :test

repo = ENV['GITHUB_REPO'] || 'rstacruz/sinatra-backbone'
namespace :doc do
  desc "Builds documentation"
  task :build do
    # github.com/rstacruz/reacco
    system "reacco -a --api lib --github #{repo}"
  end

  desc "Uploads documentation"
  task :deploy => :build do
    # github.com/rstacruz/git-update-ghpages
    system "git update-ghpages -i doc #{repo}"
  end
end

task :doc => :'doc:build'
