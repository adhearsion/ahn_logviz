class AddAdhearsionLogToCall < ActiveRecord::Migration
  def change
    add_column :calls, :adhearsion_log_id, :integer
  end
end
