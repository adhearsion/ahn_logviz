class Message < ActiveRecord::Base
  attr_accessor :from, :to, :event
  belongs_to :call_event
end
