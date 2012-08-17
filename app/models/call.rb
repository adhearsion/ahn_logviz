class Call
  include Mongoid::Document

  field :id,         type: String
  field :start_time, type: DateTime
  field :end_time,   type: DateTime

  embeds_many :messages
  validates_presence_of :id
end
