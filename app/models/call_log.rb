class CallLog
  include Mongoid::Document

  field :id,         type: String
  field :start_time, type: DateTime
  field :end_time,   type: DateTime

  embeds_many :call_events
  validates_presence_of :id

  def translate
    messages.each do |message|

    end
end
