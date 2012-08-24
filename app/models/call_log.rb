class CallLog
  include Mongoid::Document

  field :id,         type: String
  field :calls,      type: Hash

  embeds_many :call_events, autosave: true
  validates_presence_of :id

  def start_time
    self.call_events.min(:time)
  end

  def end_time
    self.call_events.max(:time)
  end
end
