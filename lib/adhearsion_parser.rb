class AdhearsionParser
  TIMESTAMP = /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/

  def initialize(log, ahn_log, line_number, pb_user)
    @log = log
    @ahn_log = ahn_log
    @line_number = line_number
    @pb_user = pb_user
  end

  def run
    begin
      until @log.eof? do
        new_event get_next_message
      end
    rescue EOFError
      @log.close
    ensure
      @ahn_log.save
    end
  end

  def timestamped?(message)
    (message =~ /#{TIMESTAMP}/) == 0
  end

  def readable?(message)
    (message =~ /#{TIMESTAMP} TRACE/) == 0 || (message =~ /#{TIMESTAMP} ERROR/) == 0
  end

  def get_time(message)
    time_string = message.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/).to_s
    DateTime.strptime time_string, "%Y-%m-%d %H:%M:%S" if time_string
  end

  def get_next_message
    @line_number += 1 until readable? @log.readline(@line_number)
    message = @log.readline(@line_number)
    @line_number += 1
    until timestamped?(line = @log.readline(@line_number))
      message += line
      @line_number += 1
    end
    message
  end

  def get_event(message)
    #Dummy method: Implementation varies depending on type of log parsed
  end

  def new_event(call, message)
    event = get_event message
    call.call_events.create log: message, time: get_time(message), 
      from: event[:from], to: event[:to], event: event[:event] if event
  end

end
