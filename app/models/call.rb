class Call < ActiveRecord::Base
  attr_accessible :adhearsion_log_id, :ahn_call_id, :is_master, :master_call_id, :sip_address, :start_time
end
