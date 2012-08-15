class LogParser

  def initialize(path_to_file)
    @path = path_to_file
    @entities = {'adhearsion' => 'Adhearsion'}
    @joined_calls = []
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0
  end

  def get_event(message)
    message_data = []
    case message
    when /RECEIVING \(presence\)/
      call_id = extract_call_id_from_address message.split(" ")[7].delete("\"").delete("from=")
      if message =~ /offer/
        from = call_id
        to = "adhearsion"
        event = "Dial"

        message_data = [{from: from, to: to, event: event}]
      elsif message =~ /ringing/
        from = "adhearsion"
        to = call_id
        event = "Ringing"

        message_data = [{from: from, to: to, event: event}]
      elsif message =~ /answered/
        from = call_id
        to = call_id
        event = "Answered"

        message_data = [{from: from, to: to, event: event}]
      elsif message =~ /joined/
        from = [call_id, message.split("<joined ")[1].split(" ")[1].split("\"/>")[0].delete("call-id=\"")]
        to = new_joined_call from
        event = "Joined"

        from.each do |f|
          message_data += [{from: f, to: to, event: event}]
        end

      elsif message =~ /unjoined/
        from = get_joined_call call_id
        to = [call_id, message.split("<unjoined ")[1].split(" ")[1].split("\"/>")[0].delete("call-id=\"")]
        event = "Unjoined"

        to.each do |t|
          message_data += [{from: from, to: t, event: event}]
        end

      elsif message =~ /end/
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
end