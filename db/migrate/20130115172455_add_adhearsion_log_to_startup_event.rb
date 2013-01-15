class AddAdhearsionLogToStartupEvent < ActiveRecord::Migration
  def change
    add_column :startup_events, :adhearsion_log_id, :string
  end
end
