class AdhearsionLog
  include Mongoid::Document

  embeds_many :call_logs
end
