class CallLog
  include Mongoid::Document

  field :id,        type: String
  field :post_data, type: String
  field :calls,     type: Hash
  field :image_url, type: String

  embeds_many :call_events, autosave: true
  validates_presence_of :id

  def start_time
    self.call_events.min(:time)
  end

  def end_time
    self.call_events.max(:time)
  end

  def translate
    self.post_data = "title Adhearsion Call #{self.id}\n"
    self.calls.each do |k, v|
      self.post_data += "participant #{v} as #{k}\n"
    end
    self.call_events.each do |event|
      self.post_data += "#{event.message[:from]}->#{event.message[:to]}: #{event.message[:event]}\n"
    end
  end
end
