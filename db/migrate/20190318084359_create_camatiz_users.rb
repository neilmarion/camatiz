class CreateCamatizUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :camatiz_users do |t|
      t.string :name
      t.string :slack_id
      t.integer :channel_id

      t.timestamps
    end
  end
end
