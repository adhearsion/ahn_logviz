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
      event = { to: "#{join_node['call-id']}@#{@ahn_domain}",
                from: "#{xml.xpath("//iq")[0]['to']}",
                event: "Join" }
    when /<dial/
      event = process_dial xml
    when /<output/
      event = process_output xml
    else
      event = nil
    end
    event
  end

  def process_received_iq(xml)
  end

  def process_received_presence(xml)
    case xml.to_s
    when /<offer/
      event = process_offer xml
    when /<ringing/
      jid = xml.xpath("//presence")[0]['from']
      event = { from: jid, to: jid, event: "Ringing" }
    when /<answered/
      jid = xml.xpath("//presence")[0]['from']
      event = { from: jid, to: jid, event: "Answer" }
    when /<input/
      event = process_input xml
    else
      event = nil
    end
    event
  end

  def process_dial(xml)
    dial_node = xml.xpath("//dial")[0] 
    master_call = @ahn_log.calls.where(sip_address: dial_node["from"]).last
    slave_sip = dial_node["to"]
    ref_node = nokogirize!(get_next_message).xpath("//ref")[0]
    slave_call_id = "#{ref_node["id"]}@#{@ahn_domain}"
    @ahn_log.calls.create(is_master: false, sip_address: slave_sip,
                          master_call_id: master_call.id,
                          ahn_call_id: slave_call_id)
    { from: master_call.ahn_call_id, to: slave_call_id, event: "Dial" } if ref_node["id"]
  end

  def process_offer(xml)
    if xml.xpath("//presence")[0]['to'] == @pb_user
      sip_address = xml.xpath("//offer")[0]['from']
      ahn_call_id = xml.xpath("//presence")[0]['from']
      master_call = @ahn_log.calls.create(is_master: true, sip_address: sip_address, ahn_call_id: ahn_call_id)
      @ahn_log.calls.create(is_master: false, master_call_id: master_call.id, sip_address: "Adhearsion", ahn_call_id: @pb_user)
      { from: ahn_call_id, to: @pb_user, event: "Call" }
    else
      nil
    end
  end

  def process_input(xml)
    case xml.to_s
    when /<match/
      ahn_call_id = xml.xpath("//presence")[0]['from']
      input = xml.xpath("//input")[0].inner_text
      event = { from: ahn_call_id, to: ahn_call_id, event: "ASR Input: \"#{input}\""}
    when /<nomatch/
      ahn_call_id = xml.xpath("//presence")[0]['from']
      event = { from: ahn_call_id, to: ahn_call_id, event: "ASR NoMatch"}
    else
      event = nil #Waiting for data
    end
    event
  end

  def process_output(xml)
    ahn_call_id = xml.xpath("//iq")[0]['to']
    if xml.xpath("//audio").empty?
      output = xml.xpath("//speak")[0].inner_text
      { from: ahn_call_id, to: ahn_call_id, event: "TTS Output: \"#{output}\"" }
    else
      {from: ahn_call_id, to: ahn_call_id, event: "Output: Audio File" }
    end
  end
  
end
