class AdhearsionParser
  def initialize(log, ahn_log, line_number, pb_user)
    @log = log
    @ahn_log = ahn_log
    @line_number = line_number
    @pb_user = pb_user
  end

  def run
    begin
      until @log.eof? do
        @joined_calls = []
        read_next_call
      end
    rescue EOFError
      @log.close
    ensure
      @call_log.save
    end
  end

  def readable?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0 || (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] ERROR/) == 0
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def hungup?(call_log)
    calls = call_log.calls.all
    call_events = call_log.call_events
    num_hungup = 1 #We don't wait for Adhearsion to hangup
    @joined_calls.each do |joined_call|
      num_hungup += 1 if joined_call[:calls_connected] == 0
    end
    calls.each do |call|
      num_hungup += 1 unless call_log.call_events.messages.where(from: call.ahn_call_id, event: "Hangup").empty?
    end
    num_hungup == calls.length
  end

  def create_event(log, time_string, data)
    data[:event].each do |event|
      call_event = @call_log.call_events.create log: log, time: Date.strptime(time_string, "%Y-%m-%d %H:%M:%S")
      call_event.message.create from: data[:from], to: data[:to], event: event
    end
  end
  
  def read_next_call
    @call_log = @ahn_log.call_logs.create
    @call_log.calls.create ahn_call_id: @pb_user, call_name: "Adhearsion"
    until hungup? @call_log
      message = @log.readline @line_number
      @line_number += 1
      until timestamped? @log.readline(@line_number)
        message += @log.readline @line_number
        @line_number += 1
      end
      get_event message 
    end
  end

  def get_event(message)
  end
end
