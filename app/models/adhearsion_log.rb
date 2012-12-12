class AdhearsionLog < ActiveRecord::Base
  has_many :call_logs
end
