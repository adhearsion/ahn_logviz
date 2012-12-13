class AddAdhearsionCallNameToCallLog < ActiveRecord::Migration
  def change
    add_column :call_logs, :ahn_call_name, :string
  end
end
