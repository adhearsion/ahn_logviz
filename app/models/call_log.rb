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

  def event_array
    events_array = []
    self.call_events.all.each do |event|
      events_array += [{:log => event.log, :message => {:to => event.message.to, :from => event.message.from, :event => event.message.event}}.to_json]
    end
    events_array
  end

  def call_array
    calls_array = []
    self.calls.all.each do |call|
      calls_array += ["#{call.ahn_call_id}", "#{call.call_name}"]
    end
    calls_array
  end
end
