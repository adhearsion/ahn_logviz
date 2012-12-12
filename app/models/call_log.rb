class CallLog < ActiveRecord::Base
  belongs_to :adhearsion_log
  has_many :calls
  has_many :call_events
  def start_time
    self.call_events.minimum(:time)
  end
  
  def end_time
    self.call_events.maximum(:time)
  end
end
