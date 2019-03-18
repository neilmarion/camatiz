module Camatiz
  class App < SlackRubyBot::Server
    def initialize(options = {})
      token = ENV['CAMATIZ_SLACK_API_TOKEN'] || raise("Missing ENV['CAMATIZ_SLACK_API_TOKEN']")
      super(token: token)
    end

    def self.instance
      @instance ||= new
    end
  end
end
