class CallLog < ActiveRecord::Base
  belongs_to :adhearsion_log
  has_many :calls
  has_many :call_events
end
