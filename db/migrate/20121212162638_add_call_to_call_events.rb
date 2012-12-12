class AddCallToCallEvents < ActiveRecord::Migration
  def change
    add_column :call_events, :call_id, :integer
  end
end
