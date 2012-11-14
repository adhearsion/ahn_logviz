class AdhearsionLog
  include Mongoid::Document

  field       :log_url, :type => String
  field       :log, :type => Array
  has_many    :call_logs
end
