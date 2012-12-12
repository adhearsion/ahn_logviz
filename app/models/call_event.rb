class CallEvent < ActiveRecord::Base
  belongs_to :call_log
  has_one :message
end
