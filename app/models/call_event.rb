class CallEvent < ActiveRecord::Base
  attr_accessible :call_id, :event, :from, :log, :time, :to
end
