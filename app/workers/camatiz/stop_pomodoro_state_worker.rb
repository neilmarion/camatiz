module Camatiz
  class StopPomodoroStateWorker
    include Sidekiq::Worker

    def perform(channel_id, state, inc)
      channel = Channel.find_by(id: channel_id)

      return unless channel &&
        channel.state == state &&
        channel.inc == inc

      text = case state
      when Channel::POMODORO
        "#{channel.pomodoro_minutes} minutes of Pomodoro is done. Enter `short break` or `long break`."
      when Channel::LONG_BREAK
        "#{channel.long_break_minutes} minutes of long break is done. Enter `start` to start Pomodoro."
      when Channel::SHORT_BREAK
        "#{channel.short_break_minutes} minutes of short break is done. Enter `start` to start Pomodoro."
      end

      channel.update_attributes({
        state: Channel::STOP,
        inc: channel.inc + 1,
        state_started_at: nil,
      })

      states = channel.states.where({
        inc: inc,
        name: state,
        completed: false,
      })
      states.update_all(completed: true)

      channel.subscribers.each do |subscriber|
        SLACK_CLIENT.chat_postMessage({
          channel: subscriber.slack_id,
          text: text,
          as_user: true,
        })
      end
    end
  end
end
