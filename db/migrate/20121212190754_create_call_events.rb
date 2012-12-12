class CreateCallEvents < ActiveRecord::Migration
  def change
    create_table :call_events do |t|
      t.integer :call_log_id
      t.integer :message_id
      t.text :log
      t.datetime :time

      t.timestamps
    end
  end
end
