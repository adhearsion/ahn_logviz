class ChangeAdhearsionLogLogToBlob < ActiveRecord::Migration
  def up
    change_table :adhearsion_logs do |t|
      t.remove :log
      t.binary :log
    end
  end

  def down
    change_table :adhearsion_logs do |t|
      t.remove :log
      t.string :log
    end
  end
end
