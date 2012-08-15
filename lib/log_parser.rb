class LogParser

  def initialize(path_to_file)
    @path = path_to_file
    @entities = {'adhearsion' => 'Adhearsion'}
    @joined_calls = []
    @log = File.open(@path)
    @lines = @log.readlines
    @line_count = 0
    @event_data = ""
    @post_data = ""
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0
  end

  def read_call
    until first_event = get_event read_next_message
      read_next_message
    end
    main_call = first_event[:from]
    translate first_event
    current_event = []
    until current_event[0][:event] == "Hangup" && current_event[0][:to] == main_call
      translate get_event(read_next_message)
    end
  end

  def read_next_message
    until trace_message? @lines[@line_count]
      @line_count ++
    end
    message = line = @lines[@line_count]
    @line_count ++
    until timestamped? line
      message += line unless timestamped? line
      @line_count ++
    end
    message
  end

  def get_event(message)
    message_data = []
    case message
    when /RECEIVING \(presence\)/
      call_id = extract_call_id_from_address message.split(" ")[7].delete("\"").delete("from=")
      case message
      when /offer/
        from = call_id
        to = "adhearsion"
        event = "Dial"

        message_data = [{from: from, to: to, event: event}]
      when /ringing/
        from = "adhearsion"
        to = call_id
        event = "Ringing"

        message_data = [{from: from, to: to, event: event}]
      when /answered/
        from = call_id
        to = call_id
        event = "Answered"

        message_data = [{from: from, to: to, event: event}]
      when /joined/
        from = [call_id, message.split("<joined ")[1].split(" ")[1].split("\"/>")[0].delete("call-id=\"")]
        to = new_joined_call from
        event = "Joined"

        from.each do |f|
          message_data += [{from: f, to: to, event: event}]
        end

      when /unjoined/
        from = get_joined_call call_id
        to = [call_id, message.split("<unjoined ")[1].split(" ")[1].split("\"/>")[0].delete("call-id=\"")]
        event = "Unjoined"

        to.each do |t|
          message_data += [{from: from, to: t, event: event}]
        end

      when /end/
        from = call_id
        to = call_id
        event = "Hangup"

        message_data = [{from: from, to: to, event: event}]
      end
    end
    message_data
  end

  def extract_call_id_from_address(address)
    address.split("@")[0]
  end

  def new_joined_call(calls = [])
    @joined_calls[@joined_calls.length] = {:calls => calls, :name => "Joined Call #{@joined_calls.length + 1}", :ref => "jc#{@joined_calls.length}"}
  end

  def new_call_ref(call_id)
    @entities["#{call_id}"] = "Call #{@entities.length + 1}"
  end

  def get_joined_call(call_id)
    joined_call = nil
    @joined_calls.each do |call_ref|
      call_ref[:calls].each do |call|
        if call_id == call
          match = true
        end
      end
      joined_call = call_ref[:ref] if match
    end
  end

  def translate(data)
    data.each do |event|
      new_call_ref event[:to] unless @entities.keys.include? event[:to]
      new_call_ref event[:from] unless @entities.keys.include? event[:from]
      @event_data += "#{event[:from]}->#{event[:to]}: #{event[:event]}\n"
    end
  end
end