class CreateCallEvents < ActiveRecord::Migration
  def change
    create_table :call_events do |t|
      t.hash :message
      t.time :time
      t.text :log

      t.timestamps
    end
  end
end
