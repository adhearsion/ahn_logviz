class CreateAdhearsionLogs < ActiveRecord::Migration
  def change
    create_table :adhearsion_logs do |t|
      t.datetime :start_time
      t.string :name
      t.string :log

      t.timestamps
    end
  end
end
