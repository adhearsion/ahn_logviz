require 'nokogiri'
require_relative "./adhearsion_parser"

class RayoParser < AdhearsionParser
  def initialize(log, ahn_log, line_number, pb_user)
    super(log, ahn_log, line_number, pb_user)
    @ahn_domain = get_domain pb_user
  end

  def nokogirize!(message)
    message = message.split(")")[1]
    xml = Nokogiri::XML message
    xml.remove_namespaces!
  end

  def get_domain(jid)
    jid.split("@")[1]
  end

  def get_event(message)
    case message
    when /SENDING/
      xml = nokogirize! message 
      event = xml.xpath("//iq").empty? ? nil : process_sent_iq(xml)
    when /RECEIVING \(iq\)/
      xml = nokogirize! message
      event = xml.xpath("//iq").empty? ? nil : process_received_iq(xml)
    when /RECEIVING \(presence\)/
      xml = nokogirize! message
      event = xml.xpath("//presence").empty? ? nil : process_received_presence(xml)
    when /ERROR/
      event = { from: @pb_user, to: @pb_user, event: "ERROR" }
    else
      event = nil
    end
    event
  end

  def process_sent_iq(xml)
    case xml.to_s
    when /<join/
      join_node = xml.xpath("//join")[0]
      event = { from: "#{join_node['call-id']}@#{@ahn_domain}",
                to: "#{xml.xpath("//iq")[0]['to']}",
                event: "Join" }
    when /<dial/
      event = process_dial xml
    else
      event = nil
    end
    event
  end

  def process_received_presence(xml)
    case xml.to_s
    when /<offer/
      event = process_offer xml
    else
      event = nil
    end
    event
  end

  def process_dial(xml)
    dial_node = xml.xpath("//dial")[0] 
    master_call = @ahn_log.calls.where(sip_address: dial_node["from"]).first
    slave_sip = dial_node["to"]
    ref_node = nokogirize!(get_next_message).xpath("//ref")[0]
    slave_call_id = "#{ref_node["id"]}@#{@ahn_domain}"
    @ahn_log.calls.create(is_master: false, sip_address: slave_sip,
                          master_call_id: master_call.id,
                          ahn_call_id: slave_call_id)
    { from: master_call.ahn_call_id, to: slave_call_id, event: "Dial" }
  end
  
end
