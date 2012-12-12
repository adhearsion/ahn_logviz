class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.integer :call_log_id
      t.string :ahn_call_id
      t.string :call_name

      t.timestamps
    end
  end
end
