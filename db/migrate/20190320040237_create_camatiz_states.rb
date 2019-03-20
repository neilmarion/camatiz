class CreateCamatizStates < ActiveRecord::Migration[5.0]
  def change
    create_table :camatiz_states do |t|
      t.string :name
      t.integer :user_id
      t.integer :inc
      t.integer :minutes
      t.boolean :completed, default: false

      t.timestamps
    end
  end
end
