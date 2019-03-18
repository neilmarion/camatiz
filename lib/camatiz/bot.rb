module Camatiz
  class Bot < ::SlackRubyBot::Commands::Base
    delegate :client, to: :instance

    def self.run
      instance.run
    end

    def self.instance
      Camatiz::App.instance
    end

    def self.call(client, data, _match)
      client.say(channel: data.channel, text: "Sorry <@#{data.user}>, I don't understand that command!", gif: 'understand')
    end
  end
end
