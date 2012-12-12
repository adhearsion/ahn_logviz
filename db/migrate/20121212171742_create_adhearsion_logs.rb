class CreateAdhearsionLogs < ActiveRecord::Migration
  def change
    create_table :adhearsion_logs do |t|
      t.string :log_url
      t.text :log

      t.timestamps
    end
  end
end
