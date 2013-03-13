migration "create the adhearsion_logs table" do
  database.create_table :adhearsion_logs do
    String   :id, primary_key: true
    String   :name
    DateTime :created_at
    DateTime :start_time
    Blob     :log, length: 1024000
  end
end

migration "create the calls table" do
  database.create_table :calls do
    String   :id, primary_key: true
    DateTime :start_time
    String   :sip_address
    String   :uuid
    Boolean  :is_master
    String  :master_id
    String   :adhearsion_log_id
  end
end

migration "create the call_events table" do
  database.create_table :call_events do
    primary_key :id
    String      :call_id
    String      :from
    String      :to
    String      :action
    DateTime    :time
    String      :log
  end
end