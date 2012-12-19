require 'nokogiri'

class RayoParser
  def initialize(log, ahn_log, line_number, pb_user)
    @log = log
    @ahn_log = ahn_log
    @line_number = line_number
    @pb_user = pb_user
    @stored_line = ""
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

  def read_next_call
    @call_log = @ahn_log.call_logs.create
    @call_log.calls.create ahn_call_id: @pb_user, call_name: "Adhearsion"
    until hungup? @call_log 
      get_event @log.readline(@line_number)
      line_number += 1
    end
  end

  def get_event(message)
    if readable? message
      time = message.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/).to_s
      case message
      when /Punchblock::Connections::XMPP: SENDING/
        xml = Nokogiri::XML message.split(")")[1]
        unless xml.xpath("//iq").empty?
          event_data = process_sent_iq xml.xpath("//iq")[0]
        else
          event_data = nil
        end
      when /Punchblock::Connection::XMPP: RECEIVING \(presence\)/
        xml = Nokogiri::XML message.split(")")[1]
        event_data = process_presence xml.xpath("//presence")
      else
      end
    end
  end

  def process_sent_iq(node)
    event_hash = {}
    event_hash[:from] = node["from"] 
    event_hash[:to] = node["to"]
    case node.child.name
    when "output"
      event_hash[:event] = process_output_iq node
    when "input"
      event_hash[:event] = "Getting Input"  
    else
      return nil
    end
    event_hash[:event].nil? ? nil : event_hash
  end

  def process_received_iq(node)
    if node["type"] == "error"
      process_error_iq
    else
      nil
    end
  end

  def process_presence(node)
    event_hash = { from: node["from"], to: node["to"] }
    case Nokogiri::XML::Node
    when node.xpath("//ringing")[0]
      event_hash[:to] = event_hash[:from]
      event_hash[:event] = "Ringing"
    when node.xpath("//result//interpretation")[0]
      process_asr_input node
    when node.xpath("//joined")[0]
      process_joined_call node
    when node.xpath("//unjoined")[0]
    when node.xpath("//end//hangup")[0]
      event_hash[:to] = event_hash[:from]
      event_hash[:event] = "Hangup"
    else
    end
  end

  def process_output_iq(node)
    unless (speak_node = node.xpath "//speak").empty?
      event = []
      event += ["Output: \"#{speak_node.inner_text}\""] unless speak_node.inner_text == ""
      event += ["Output: Audio File"] unless node.xpath("//audio").empty?
    else
      event = nil
    end
    event
  end

  def process_error_iq(node)

  end

end

