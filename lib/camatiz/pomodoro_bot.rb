module Camatiz
  class PomodoroBot < Camatiz::Bot
    command 'start' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      unless user
        user = User.create({
          name: "<@#{data.user}>",
          slack_id: data.user
        })
        channel = user.created_channels.create
        user.subscribe(channel)
      end

      channel = user.reload.subscribed_channel
      user.pomodoro(channel)
    end

    command 'stop' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      channel = user.subscribed_channel
      user.stop(channel)
    end

    command 'long break' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      channel = user.subscribed_channel
      user.long_break(channel)
    end

    command 'short break' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      channel = user.subscribed_channel
      user.short_break(channel)
    end

    command 'settings' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      channel = user.subscribed_channel
      client.say(channel: data.channel, text: channel.settings_text)
    end

    command 'channels' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      channel = user.subscribed_channel
      text = Channel.all.map do |c|
        "(#{c.id}) *#{c.name}* (#{c.state.sub("_", " ")}) - subscribers: #{c.subscribers.map(&:name).join(", ")} #{user.subscribed_channel.id == c.id ? "*<<<*" : nil}"
      end
      text << "\n_Use the id in the parentheses to subscribe_"
      client.say(channel: data.channel, text: text.join("\n"))
    end

    command 'set' do |client, data, match|
      user = User.find_by(slack_id: data.user)
      channel = user.subscribed_channel

      exp = match["expression"]
      length = exp.split(" ").last.to_i
      if /^pomodoro \d+$/ === exp
        channel.update_attributes(pomodoro_minutes: length)
      elsif /^long break \d+$/ === exp
        channel.update_attributes(long_break_minutes: length)
      elsif /^short break \d+$/ === exp
        channel.update_attributes(short_break_minutes: length)
      end

      client.say({
        channel: data.channel,
        text: "Setting updated! This will take effect after current state stops",
      })
    end

    command 'state' do |client, data, match|
      user = User.find_by(slack_id: data.user)
      channel = user.subscribed_channel

      client.say({
        channel: data.channel,
        text: channel.current_state_text,
      })
    end

    command 'stats' do |client, data, match|
      user = User.find_by(slack_id: data.user)

      client.say({
        channel: data.channel,
        text: user.stats_for_the_day_text,
      })
    end

    command 'subscribe' do |client, data, match|
      user = User.find_by(slack_id: data.user)
      channel_id = match["expression"].to_i
      channel = Channel.find_by(id: channel_id)

      if channel
        user.subscribe(channel)
      else
        client.say({
          channel: data.channel,
          text: "Channel not found!",
        })
      end
    end

    command 'quit' do |client, data, match|
      user = User.find_by(slack_id: data.user)
      channel = user.subscribed_channel
      user.unsubscribe(channel)
    end

    command 'change name' do |client, data, match|
      user = User.find_by(slack_id: data.user)
      channel = user.subscribed_channel
      new_name = match["expression"]

      channel.set_name(new_name, user)
    end

    command 'camatiz help' do |client, data, match|
      user = User.find_by(slack_id: data.user)
      channel = user.subscribed_channel

      text = "- `start` to start #{channel.pomodoro_minutes} minutes of pomodoro :tomato:\n" +
        "- `short break` to start #{channel.short_break_minutes} minutes of short break :clock1:\n" +
        "- `long break` to start #{channel.long_break_minutes} minutes of long break :clock1::clock1:\n" +
        "- `stop` to stop current state :black_square:\n" +
        "- `state` to get current state of pomodoro e.g. time remaining :chart:\n" +
        "- `settings` to display pomodoro settings of the current channel :gear:\n" +
        "- `channels` to display all pomodoro channels and their ids :woman-woman-boy-boy:\n" +
        "- `set pomodoro <minutes>` to set pomodoro duration :pencil2:\n" +
        "- `set short break <minutes>` to set short break duration :pencil2:\n" +
        "- `set long break <minutes>` to set long break duration :pencil2:\n" +
        "- `change name <channel name>` to set the channel's name :pencil2:\n" +
        "- `stats` to checkout your stats for the day :computer:\n" +
        "- `subscribe <channel id>` to join other channels and sync up your pomodoro with others :white_check_mark:\n" +
        "- `quit` to quit current channel :fu:\n"

      client.say(channel: data.channel, text: text)
    end

    private

    def respond_with_error(slack_channel, &block)
      begin
        block.call
      rescue Exception => e
        ping_error(slack_channel)
      end
    end

    def ping_error(slack_channel)
      SLACK_CLIENT.chat_postMessage({
        channel: slack_channel,
        text: "Something went wrong. 500 error!",
        as_user: true,
      })
    end
  end
end

if Rails.env.production?
  Thread.abort_on_exception = true
  Thread.new do
    begin
      Camatiz::PomodoroBot.run
    rescue Slack::Web::Api::Errors::SlackError
      raise("Invalid ENV['CAMATIZ_SLACK_API_TOKEN']")
    rescue StandardError => e
    end
  end
end

# NOTE: Only run the bot on a running server, not CLI
if Rails.const_defined?('Server') && !Rails.env.production?
  Thread.abort_on_exception = true
  Thread.new do
    begin
      Camatiz::PomodoroBot.run
    rescue Slack::Web::Api::Errors::SlackError
      raise("Invalid ENV['CAMATIZ_SLACK_API_TOKEN']")
    rescue StandardError => e
    end
  end
end
