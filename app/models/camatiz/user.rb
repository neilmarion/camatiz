module Camatiz
  class User < ApplicationRecord
    has_many :created_channels, {
      foreign_key: :creator_id,
      class_name: "Camatiz::Channel"
    }

    has_one :subscribed_channel, {
      foreign_key: :id,
      primary_key: :channel_id,
      class_name: "Camatiz::Channel"
    }

    has_many :states

    # NOTE: pomodoro is a
    # verb in this context
    def pomodoro(channel)
      channel.pomodoro(self)
    end

    def stop(channel)
      channel.stop(self)
    end

    def short_break(channel)
      channel.short_break(self)
    end

    def long_break(channel)
      channel.long_break(self)
    end

    def subscribe(channel)
      cur_channel = self.subscribed_channel
      return if cur_channel && cur_channel.id == channel.id
      # NOTE: So weird that update_attributes errors out
      self.update_columns(channel_id: channel.id)

      cur_channel&.destroy_if_no_subscribers

      channel.subscribers.each do |subscriber|
        next if self.id == subscriber.id

        SLACK_CLIENT.chat_postMessage({
          channel: subscriber.slack_id,
          text: "#{self.name} joined the channel",
          as_user: true,
        })
      end
    end

    def unsubscribe(channel)
      cur_channel = self.subscribed_channel
      return if cur_channel.subscribers.count == 1

      new_channel = self.created_channels.create
      self.subscribe(new_channel)

      cur_channel.subscribers.each do |subscriber|
        next if self.id == subscriber.id
        SLACK_CLIENT.chat_postMessage({
          channel: subscriber.slack_id,
          text: "#{self.name} left the channel",
          as_user: true,
        })
      end
    end

    def stats_for_the_day_text
      s = states.where({
        created_at: Time.current.beginning_of_day..Time.current.end_of_day,
        completed: true,
      })

      p = s.where(name: Channel::POMODORO)
      l = s.where(name: Channel::LONG_BREAK)
      s = s.where(name: Channel::SHORT_BREAK)

      "Today, you have completed:\n" +
      "- #{p.count} pomodoros with a total of #{p.sum(:minutes)} minutes\n" +
      "- #{s.count} short breaks with a total of #{s.sum(:minutes)} minutes\n" +
      "- #{l.count} long breaks with a total of #{l.sum(:minutes)} minutes\n" +
      ":100: :100: :100:"
    end
  end
end
