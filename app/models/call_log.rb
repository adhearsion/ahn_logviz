class CallLog
  include LogParseHelper
  include Mongoid::Document

  field :id,        type: String
  field :post_data, type: String
  field :calls,     type: Hash

  embeds_many :call_events
  belongs_to  :adhearsion_log
  accepts_nested_attributes_for :adhearsion_log
  validates_presence_of :id

  def start_time
    self.call_events.min(:time)
  end

  def end_time
    self.call_events.max(:time)
  end

  def call_array
    call_array = []
    self.calls.each do |k,v|
      call_array += [[k, v]]
    end
    call_array
  end

  def event_array
    event_array = []
    self.call_events.all.to_a.each do |event|
      event_array += [event.message.to_json.gsub('=', ':').delete("\\")]
    end
    event_array.to_a
  end
end
