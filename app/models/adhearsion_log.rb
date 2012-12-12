class AdhearsionLog < ActiveRecord::Base
  attr_accessor :log_url, :log
  has_many :call_logs
end
