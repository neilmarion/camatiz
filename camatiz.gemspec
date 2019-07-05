$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "camatiz/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "camatiz"
  s.version     = Camatiz::VERSION
  s.authors     = ["Neil Marion dela Cruz"]
  s.email       = ["nmfdelacruz@gmail.com"]
  s.homepage    = "https://github.com/carabao-capital/camatiz"
  s.summary     = "Slack Pomodoro App"
  s.description = "Slack Pomodoro App"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency 'rails', '~> 5.0.1', '>= 5.0.1'
  s.add_dependency 'httparty'
  s.add_dependency 'sidekiq'
  s.add_dependency 'slack-ruby-client'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'slack-ruby-bot'
  s.add_dependency 'faye-websocket', '~> 0.10.2', '> 0.10.2'
  s.add_development_dependency 'pg'
end
