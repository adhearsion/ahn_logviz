class CreateStartupEvents < ActiveRecord::Migration
  def change
    create_table :startup_events do |t|
      t.string :key
      t.string :value
      t.integer :adhearsion_log_id

      t.timestamps
    end
  end
end
