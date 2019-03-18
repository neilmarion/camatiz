module Camatiz
  class PomodoroBot < Camatiz::Bot
    command 'start' do |client, data, match|
      client.say(channel: data.channel, text: match['expression'])
    end
  end
end

return if ENV['RAILS_ENV'] == 'test'

Thread.abort_on_exception = true
Thread.new do
  begin
    Camatiz::PomodoroBot.run
  rescue Slack::Web::Api::Errors::SlackError
    raise("Invalid ENV['CAMATIZ_SLACK_API_TOKEN']")
  end
end
