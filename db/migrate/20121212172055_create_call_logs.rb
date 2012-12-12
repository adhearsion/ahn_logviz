class CreateCallLogs < ActiveRecord::Migration
  def change
    create_table :call_logs do |t|
      t.integer :adhearsion_log_id

      t.timestamps
    end
  end
end
