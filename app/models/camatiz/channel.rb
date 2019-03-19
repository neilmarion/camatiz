module Camatiz
  class Channel < ApplicationRecord
    attr_accessor :triggerer, :prev_state, :next_state

    POMODORO = "pomodoro"
    STOP = "stop"
    LONG_BREAK = "long_break"
    SHORT_BREAK = "short_break"

    before_create :set_name
    belongs_to :created_user, {
      foreign_key: :creator_id,
      class_name: "Camatiz::User"
    }

    has_many :subscribers, {
      foreign_key: :channel_id,
      class_name: "Camatiz::User"
    }

    has_many :states, through: :subscribers

    def pomodoro(triggerer)
      update_with_extras(triggerer, POMODORO)
    end

    def stop(triggerer)
      update_with_extras(triggerer, STOP)
    end

    def short_break(triggerer)
      update_with_extras(triggerer, SHORT_BREAK)
    end

    def long_break(triggerer)
      update_with_extras(triggerer, LONG_BREAK)
    end

    def settings_text
      "*channel name:* #{self.name}\n" +
      "*created by:man-tipping-hand::* #{self.created_user.name}\n" +
      "*pomodoro length :tomato::* #{self.pomodoro_minutes} minutes\n" +
      "*short break length :clock1::* #{self.short_break_minutes} minutes\n" +
      "*long break length :clock1::clock1::* #{self.long_break_minutes} minutes\n"
    end

    def current_state_text
      state_length = case self.state
                     when POMODORO
                       self.pomodoro_minutes
                     when LONG_BREAK
                       self.long_break_minutes
                     when SHORT_BREAK
                       self.short_break_minutes
                     end

      text = "*channel name:* #{self.name}\n" +
        "*current state:* #{self.state}\n"
      return text if self.state == STOP

      will_stop_at = self.state_started_at + state_length.minutes
      total_seconds = will_stop_at - Time.current

      seconds = total_seconds % 60
      minutes = (total_seconds / 60) % 60
      hours = total_seconds / (60 * 60)

      remaining = format("%02d:%02d:%02d", hours, minutes, seconds)
      text + "*time remaining:* #{remaining}\n"
    end

    def destroy_if_no_subscribers
      self.destroy if self.subscribers.blank?
    end

    def set_name(name=nil, user=nil)
      if name && user
        self.update_attributes(name: name)
        self.subscribers.each do |subscriber|
          SLACK_CLIENT.chat_postMessage({
            channel: subscriber.slack_id,
            text: "#{user.name} changed the channel's name to #{name}",
            as_user: true,
          })
        end
      else
        self.name = "#{created_user.name}'s channel #{self.id}"
      end
    end

    private

    def update_with_extras(triggerer, next_state)
      @triggerer = triggerer
      @prev_state = self.state
      @next_state = next_state

      return if @prev_state == @next_state

      i = self.inc + 1
      self.update_attributes({
        state: next_state,
        inc: i,
        state_started_at: next_state != STOP ? Time.current : nil,
      })

      unless next_state == STOP
        length = get_length(next_state)
        triggerer.states.create({
          name: next_state,
          inc: i,
          minutes: length/60,
        })
        stop_pomodoro_state
      end

      notify_subscribers
    end

    def notify_subscribers
      text = case self.state
      when POMODORO
        "#{triggerer.name} started #{next_state} :tomato:"
      when LONG_BREAK
        "#{triggerer.name} started #{next_state} :fast_parrot::fast_parrot:"
      when SHORT_BREAK
        "#{triggerer.name} started #{next_state} :fast_parrot:"
      when STOP
        "#{triggerer.name} stopped #{prev_state} :sadparrot:"
      end

      self.subscribers.each do |subscriber|
        SLACK_CLIENT.chat_postMessage({
          channel: subscriber.slack_id,
          text: text,
          as_user: true,
        })
      end
    end

    def get_length(state)
      case state
      when POMODORO
        self.pomodoro_minutes.minutes
      when LONG_BREAK
        self.long_break_minutes.minutes
      when SHORT_BREAK
        self.short_break_minutes.minutes
      end
    end

    def stop_pomodoro_state
      minutes = get_length(self.state)
      StopPomodoroStateWorker.
        perform_in(minutes,
                   self.id,
                   self.state,
                   self.inc)
    end
  end
end
