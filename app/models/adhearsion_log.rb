class AdhearsionLog
  include Mongoid::Document

  field       :log_url, type: String
  embeds_many :call_logs
end
