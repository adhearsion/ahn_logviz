class ChangeAdhearsionLogLogsToBlob < ActiveRecord::Migration
  def up
    remove_column :adhearsion_logs, :log
    add_column :adhearsion_logs, :log, :binary
  end

  def down
    remove_column :adhearsion_logs, :log
    add_column :adhearsion_logs, :log, :text
  end
end
