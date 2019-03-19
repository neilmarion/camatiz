class CreateCamatizChannels < ActiveRecord::Migration[5.0]
  def change
    create_table :camatiz_channels do |t|
      t.string :name
      t.integer :creator_id
      t.integer :pomodoro_minutes, default: 25
      t.integer :short_break_minutes, default: 5
      t.integer :long_break_minutes, default: 15
      t.integer :inc, default: 0
      t.string :state, default: "stop"
      t.datetime :state_started_at

      t.timestamps
    end
  end
end
