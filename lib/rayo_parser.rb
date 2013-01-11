require 'nokogiri'
require_relative "./adhearsion_parser"

class RayoParser < AdhearsionParser
  def initialize(log, ahn_log, line_number, pb_user)
    super(log, ahn_log, line_number, pb_user)
  end

  def get_event(message)
    time = message.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/).to_s
    case message
    when /SENDING/
      xml = Nokogiri::XML message.split(")")[1]
      if xml.xpath("//iq").empty?
        event_data = nil
      else  
        event_data = process_sent_iq message, xml.xpath("//iq")[0]
      end
    when /RECEIVING \(presence\)/
      xml = Nokogiri::XML message.split(")")[1]
      unless xml.xpath("//presence").empty?
        event_data = process_presence message, xml.xpath("//presence")[0] 
      end
    when /ERROR/
      event_data = { to: @pb_user, from: @pb_user, event: ["ERROR"] }
    else
    end
    make_event message, time, event_data if event_data
  end

  def process_sent_iq(message, node)
    event_hash = {}
    event_hash[:from] = @pb_user 
    event_hash[:to] = node["to"]
    case message
    when /output/
      event_hash[:event] = process_output_iq node
    when /input/
      event_hash[:event] = ["Getting Input"]  
    when /dial/
      event_hash[:from] = @pb_user
      event_hash[:to] = find_dial
      event_hash[:event] = ["Dial"]
    when /join/
      event_hash[:from] = process_joined_call node
      event_hash[:event] = ["Joined"]
    else
      event_hash[:event] = []
    end
    event_hash[:event].empty? ? nil : event_hash
  end

  def process_presence(message, node)
    event_hash = {}
    case message
    when /ringing/
      event_hash[:from] = node["from"]
      event_hash[:to] = event_hash[:from]
      event_hash[:event] = ["Ringing"]
    when /input/
      event_hash[:event] = ["Received Input: \"#{node.xpath("//input").inner_text}\""]
    when /unjoined/
      event_hash[:from] = node["from"]
      event_hash[:to] = find_unjoined_dest node
      event_hash[:event] = ["Unjoined"]
    when /hangup/
      event_hash[:from] = node["from"]
      event_hash[:to] = event_hash[:from]
      event_hash[:event] = ["Hangup"]
    else
      event_hash[:event] = []
    end
    event_hash[:event].empty? ? nil : event_hash
  end

  def find_dial
    call_domain = @pb_user.split("@")[1]
    xml = Nokogiri::XML get_next_message.split(")")[1] 
    if xml.xpath("//ref")[0]  
      create_call "#{xml.xpath("//ref")[0]["id"]}@#{call_domain}"
      "#{xml.xpath("//ref")[0]["id"]}@#{call_domain}"
    else
      create_call "couldnotfinddial@1.com"
      "couldnotfinddial@1.com"
    end
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
    if node.xpath("//join")[0]
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
end

