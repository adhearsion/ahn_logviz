class Message
  include Mongoid::Document

  field :message,        type: String
  field :parsed_message, type: String

  embedded_in :call
  validates_presence_of :message, :parsed_message
end
