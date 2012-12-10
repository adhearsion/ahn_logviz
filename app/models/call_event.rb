class CallEvent
  attr_accessor :log
  include Mongoid::Document

  field :message,      :type => Hash
  field :time,         :type => DateTime
  field :line_numbers, :type => Array

  embedded_in :call_log
  accepts_nested_attributes_for :call_log
  validates_presence_of :message
end
