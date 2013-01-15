class CreateStartupEvents < ActiveRecord::Migration
  def change
    create_table :startup_events do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
