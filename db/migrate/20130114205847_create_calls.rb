class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.datetime :start_time
      t.boolean :is_master
      t.integer :adhearsion_log_id
      t.integer :master_call_id
      t.string :sip_address
      t.string :ahn_call_id

      t.timestamps
    end
  end
end
