class AddCallEventToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :call_event_id, :integer
  end
end
