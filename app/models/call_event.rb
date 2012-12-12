class CallEvent < ActiveRecord::Base
  attr_accessor :time, :log 
  belongs_to :call_log
  has_many :messages
end
