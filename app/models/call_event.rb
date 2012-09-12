class CallEvent
  include Mongoid::Document

  field :message, type: Hash
  field :time,    type: DateTime

  embedded_in :call_log
  accepts_nested_attributes_for :call_log
  validates_presence_of :message
end
