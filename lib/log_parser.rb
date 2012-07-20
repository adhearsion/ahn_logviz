class LogParser

  def initialize(path_to_file)
    @path = path_to_file
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

end