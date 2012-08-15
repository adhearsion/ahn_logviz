class LogParser

  def initialize(path_to_file)
    @path = path_to_file
    @calls = {}
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0
  end

  def get_event(message)
    case message
    when /RECEIVING \(presence\)/
      call_id = extract_call_id_from_address message.split(" ")[7].delete("\"").delete("from=")
      if message =~ /offer/
        from = call_id
        to = "adhearsion"
        event = "Dial"
      elsif message =~ /ringing/
        from = "adhearsion"
        to = call_id
        event = "Ringing"
      elsif message =~ /answered/
        from = call_id
        to = call_id
        event = "Answered"
      elsif message =~ /joined/
        from = call_id
        to = message.split("<joined ")[1].split(" ")[1].split("\"/>")[0].delete("call-id=\"")
        event = "Joined"
      elsif message =~ /unjoined/
      elsif message =~ /end/
        from = call_id
        to = call_id
        event = "hangup"
      end
    end
    {from: from, to: to, event: event}
  end

  def extract_call_id_from_address(address)
    address.split("@")[0]
  end

  # def get_call_id(message)
  #   case message
  #   when /Punchblock::Translator::Asterisk::Call/, /Adhearsion::Call/, /Adhearsion::OutboundCall/
  #     call = message.split("Call:")[1].split(" ")[0].delete(":")
  #   when /::Asterisk::AGICommand/
  #     call = message.split("Call ID: ")[1].split(",")[0]
  #   else
  #     call = ""
  #   end
  # end


end