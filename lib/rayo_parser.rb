require 'nokogiri'

class RayoParser
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
    if readable? message
      time = message.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/).to_s
      case message
      when /Punchblock::Connections::XMPP: SENDING/
        xml = Nokogiri::XML message.split(")")[1]
        if xml.xpath("//iq").empty?
          event_data = nil
        else  
          event_data = process_sent_iq xml.xpath("//iq")[0]
        end
      when /Punchblock::Connection::XMPP: RECEIVING \(presence\)/
        xml = Nokogiri::XML message.split(")")[1]
        event_data = process_presence xml.xpath("//presence")[0]
      when /ERROR/
        event_data = { to: @pb_user, from: @pb_user, event: ["ERROR"] }
      else
      end
    create_event message, time, event_data
    end
  end

  def create_event(log, time_string, data)
    data[:event].each do |event|
      call_event = @call_log.call_events.create log: log, time: Date.strptime(time_string, "%Y-%m-%d %H:%M:%S")
      call_event.message.create from: data[:from], to: data[:to], event: event
    end
  end

  def process_sent_iq(node)
    event_hash = {}
    event_hash[:from] = node["from"] 
    event_hash[:to] = node["to"]
    event_hash[:event] = case node.child.name
    when "output"
      event_hash[:event] = process_output_iq node
    when "input"
      ["Getting Input"]  
    else
      []
    end
    event_hash[:event].empty? ? nil : event_hash
  end

  def process_presence(node)
    event_hash = { from: node["from"], to: node["to"] }
    case false
    when node.xpath("//ringing").empty?
      event_hash[:to] = event_hash[:from]
      event_hash[:event] = ["Ringing"]
    when node.xpath("//input").empty?
      event_hash[:event] = ["Received Input: \"#{node.xpath("//input").inner_text}\""]
    when node.xpath("//joined").empty?
      event_hash[:event] = ["Joined"]
      process_joined_call node
    when node.xpath("//unjoined").empty?
      event_hash[:to] = find_unjoined_dest node
      event_hash[:event] = ["Unjoined"]
    when node.xpath("//end//hangup").empty?
      event_hash[:to] = event_hash[:from]
      event_hash[:event] = ["Hangup"]
    else
      []
    end
    event_hash[:event].empty? nil : event_hash
  end

  def find_unjoined_dest(node)
    @call_log.calls.each do |call|
      call.ahn_call_id if call.ahn_call_id =~ /#{node.xpath("//unjoined")["call-id"].gsub("-", "\-")}/
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

  def process_joined_call(node)
    @call_log.calls.each do |call| 
      if call.ahn_call_id = node["to"]
        @joined_calls.each { |joined_call| joined_call[:calls_connected] += 1 if joined_call[:id] == node["to"] }
      end
    end
    @joined_calls += [{id: node["to"], calls_connected: 1}]
    @call_log.calls.create ahn_call_id: node["to"], call_name: "Bridge #{@joined_calls.length}" 
  end

end

