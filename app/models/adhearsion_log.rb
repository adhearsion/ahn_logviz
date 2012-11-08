class AdhearsionLog
  include Mongoid::Document

  field       :log_url, :type => String
  has_many    :call_logs
end
