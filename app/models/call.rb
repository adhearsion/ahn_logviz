class Call < ActiveRecord::Base
  attr_accessor :calls
  belongs_to :adhearsion_log
  has_many :call_events
end
