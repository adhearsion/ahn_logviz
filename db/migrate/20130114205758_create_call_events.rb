class CreateCallEvents < ActiveRecord::Migration
  def change
    create_table :call_events do |t|
      t.string :log
      t.string :from
      t.string :to
      t.string :event
      t.integer :call_id
      t.datetime :time

      t.timestamps
    end
  end
end
