class AdhearsionLog < ActiveRecord::Base
  has_many :call_logs
  has_many :startup_events
end
