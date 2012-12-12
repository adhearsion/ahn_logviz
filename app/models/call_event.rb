class CallEvent < ActiveRecord::Base
  attr_accessor :time, :message, :log
  belongs_to :call
end
