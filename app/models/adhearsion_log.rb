class AdhearsionLog
  include Mongoid::Document

  field       :log_url, :type => String
  field       :log, :type => Array
  has_many    :call_logs

  def parse(path_to_file)
    LogParser.new(path_to_file, self).run
  end
end
