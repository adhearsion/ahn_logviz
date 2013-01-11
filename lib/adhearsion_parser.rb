class AdhearsionParser
  def initialize(log, ahn_log, line_number, pb_user)
    @log = log
    @ahn_log = ahn_log
    @line_number = line_number
    @pb_user = pb_user
    @joined_calls = []
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
    call_log.messages.where(event: "Hangup").count >= 3 
  end

  def make_event(log, time_string, data)
    check_calls data[:from]
    check_calls data[:to]
    data[:event].each do |event|
      call_event = @call_log.call_events.create log: log, time: Date.strptime(time_string, "%Y-%m-%d %H:%M:%S")
      call_event.create_message from: data[:from], to: data[:to], event: event
    end
  end
  
  def read_next_call
    @call_log = @ahn_log.call_logs.create
    @call_log.calls.create ahn_call_id: @pb_user, call_name: "Adhearsion"
    until hungup? @call_log
      get_event get_next_message
    end
  end

  def get_next_message
    message = ""
    until readable? message
      message = @log.readline @line_number
      @line_number += 1
    end
    until timestamped? @log.readline(@line_number)
      message += "#{@log.readline(@line_number)}"
      @line_number += 1
    end
    message
  end

  def get_event(message)
  end

  def create_call(jid)
    call_num = @call_log.calls.count - @joined_calls.length
    @call_log.calls.create ahn_call_id: jid, call_name: "Call #{call_num}"
  end

  def check_calls(jid)
    create_call jid if @call_log.calls.where(ahn_call_id: jid).empty?
  end
end
