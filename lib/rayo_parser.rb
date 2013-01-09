require 'nokogiri'

class RayoParser < AdhearsionParser
  def initialize(log, ahn_log, line_number, pb_user)
    super(log, ahn_log, line_number, pb_user))
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
      when /Punchblock::Connections::XMPP: RECEIVING \(iq\)/
        xml = Nokogiri::XML message.split(")")
        event_data = process_received_iq xml.xpath("//iq")[0]
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

  def process_sent_iq(node)
    event_hash = {}
    event_hash[:from] = @pb_user 
    event_hash[:to] = node["to"]
    case node.child.name
    when "output"
      event_hash[:event] = process_output_iq node
    when "input"
      event_hash[:event] = ["Getting Input"]  
    when "dial"
      event_hash[:from] = @pb_user
      event_hash[:to] = find_dial
      event_hash[:event] = ["Dial"]
    when "join"
      event_hash[:from] = process_joined_call node
      event_hash[:event] = ["Joined"]
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

  def find_dial
    call_domain = @pb_user.split("@")[1]
    message = ""
    until readable? message
      message = @log.readline @line_number
      @line_number += 1
    end
    until timestamped? @log.readline(@line_number)
      message += "#{@log.readline @line_number}"
      @line_number += 1
    end
    xml = Nokogiri::XML message
    create_call "#{xml.xpath("//ref")[0]["id"]}@#{call_domain}"
    "#{xml.xpath("//ref")[0]["id"]}@#{call_domain}"
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
    call_domain = @pb_user.split("@")[1]
    from = "#{node.xpath("//join")[0]["call-id"]}@#{call_domain}"
    @call_log.calls.each do |call| 
      if call.ahn_call_id == node["to"]
        @joined_calls.each { |joined_call| joined_call[:calls_connected] += 1 if joined_call[:id] == node["to"] }
        return from
      end
    end
    @joined_calls += [{id: node["to"], calls_connected: 1}]
    @call_log.calls.create ahn_call_id: node["to"], call_name: "Bridge #{@joined_calls.length}" 
    from
  end
end

