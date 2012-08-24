require 'net/http'
require 'uri'

module LogParseHelper

  def new_call_log(log)
    @log = log
    @joined_calls = []
    @call_log = CallLog.new
    @call_log.calls = {"adhearsion" => "Adhearsion"}
    @line_number = 0
  end

  def read_call
    first_event = nil
    while first_event == nil do
      first_event = get_event read_next_message(@stored_line)
    end
    @main_call = first_event[0][:from]
    @call_log.id = @main_call
    translate find_dial(first_event)
    current_event = first_event
    until current_event[0][:event] == "Hangup" && current_event[0][:to] == @main_call do
      current_event = get_event read_next_message(@stored_line)
      current_event = get_event read_next_message(@stored_line) while current_event.nil?
      translate find_dial(current_event)
    end
    @call_log.save
  end

  def read_next_message(line = "")
    until trace_message? line do
      line = @log.readline
      @line_number += 1
    end
    message = line
    line = ""
    until timestamped? line do
      line = @log.readline
      @line_number += 1
      if timestamped? line
        @stored_line = line
      else
        message += line
      end
    end
    { message: message, time: DateTime.strptime(message.split("]").delete("["), "%Y-%m-%d %H:%M:%S") }
  end

  def get_event(message)
    message_data = []
    case message[:message]
    when /RECEIVING \(presence\)/
      call_id = extract_call_id_from_address message.split(" ")[7].delete("\"").gsub("from=", '').delete("-")
      case message[:message]
      when /offer/
        from = call_id
        to = nil
        event = "Dial"

        message_data = [{from: from, to: to, event: event}]
      when /ringing/
        from = call_id
        to = call_id
        event = "Ringing"

        message_data = [{from: from, to: to, event: event}]
        @main_call = to
      when /answered/
        from = call_id
        to = call_id
        event = "Answered"

        message_data = [{from: from, to: to, event: event}]
      when /[^u][^n]joined/
        from = [call_id, message.split("<joined ")[1].split(" ")[1].split("\"/>")[0].gsub("call-id=\"", '').gsub("-", '')]
        to = nil
        to = new_joined_call from if get_joined_call(from).nil?
        event = "Joined"

        if to
          from.each do |f|
            message_data += [{from: f, to: to, event: event}]
          end
        else
          message_data = nil
        end
      when /unjoined/
        from = get_joined_call(call_id)[:calls]
        to = [call_id, message.split("<unjoined ")[1].split(" ")[1].split("\"/>")[0].gsub("call-id=\"", '').delete("-")]
        event = "Unjoined"

        if from
          to.each do |t|
            message_data += [{from: from, to: t, event: event}]
          end
          remove_joined_call to
        else
          message_data = nil
        end
      when /hangup/
        from = call_id
        to = call_id
        event = "Hangup"

        message_data = [{from: from, to: to, event: event}]
      else
        message_data = nil
      end
    when /RubyAMI::Client: \[RECV\-EVENTS\]:/
      case message[:message]
      when /Newstate/
        channel = extract_channel_id_from_address message.split("Channel\"=>\"")[1].split("\"")[0]
        case message
        when /Ring/
          to = channel
          from = channel
          event = "Ringing"

          message_data = [{from: from, to: to, event: event}]
        when /\"ChannelStateDesc\"=>\"Up\"/
          message_data = [{from: channel, to: channel, event: "Answered"}]
        else
          message_data = nil
        end
      when /ConfbridgeJoin/
        channel = extract_channel_id_from_address message.split("Channel\"=>\"")[1].split("\"")[0]
        from = channel
        unless conf_bridge_exist? message.split("Conference\"=>\"")[1].split("\"")[0]
          to = new_conf_bridge message.split("Conference\"=>\"")[1].split("\"")[0]
        else
          to = message.split("Conference\"=>\"")[1].split("\"")[0]
        end

        message_data = [{from: from, to: to, event: "Joined"}]
        @main_call = from
      when /ConfbridgeLeave/
        message_data = [{from: message.split("Conference\"=>\"")[1].split("\"")[0], 
                         to: extract_channel_id_from_address message.split("Channel\"=>\"")[1].split("\"")[0], 
                         event: "Unjoined"}]
      else
        message_data = nil
      end
    when /RubyAMI::Client: \[SEND\]:/
      case message[:message]
      when /hangup/
        channel = extract_channel_id_from_address message.split("Channel: ")[1].strip
        message_data = [{from: channel, to: channel, event: "Hangup"}]
      when /originate/
        message_data = [{from: @main_call, to: nil, event: "Dial"}]
      else
        message_data = nil
      end
    else 
      message_data = nil
    end
    unless message_data.nil?
      message_data.each do |m|
        m[:time] = message[:time]
      end
    end
    message_data
  end

  def find_dial(event)
    unless event[0].nil?
      if (event[0][:event] == "Dial") && event[0][:to].nil?
        if event[0][:from] == @main_call
          next_event = get_next_event
          until next_event[0][:event] == "Ringing" do
            translate find_dial(next_event)
            next_event = get_next_event
          end
          event[0][:to] = next_event[0][:to]
          event += [{from: next_event[0][:to], to: next_event[0][:from], event: next_event[0][:event]}]
        else
          puts "Finding Dial To..."
          dial_to = get_next_event
          event[0][:to] = dial_to[0][:to]
          event += [{from: dial_to[0][:to], to: dial_to[0][:from], event: dial_to[0][:event]}]
        end
      end
      event
    else
      nil
    end
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0
  end

  def get_next_event
    next_event = nil
    next_event = get_event read_next_message(@stored_line) while next_event.nil?
    next_event
  end

  def extract_call_id_from_address(address)
    address.split("@")[0]
  end

  def extract_channel_id_from_address(address)
    address.split("/")[1].delete("-")
  end

  def new_call_ref(call_id)
    @call_log.calls["#{call_id}"] = "Call#{@call_log.calls.length}"
  end

  def new_conf_bridge(conf_name)
    @call_log.calls["#{conf_name}"] = "#{conf_name}"
    conf_name
  end

  def conf_bridge_exist?(conf_name)
    @call_log.calls.keys.include? conf_name
  end

  def new_joined_call(calls)
    @call_log.calls["jc#{@joined_calls.length}"] = "Bridge#{@joined_calls.length + 1}"
    @joined_calls += [{joined_call: @call_log.calls.keys.last, calls: calls}]
    @joined_calls.last[:joined_call]
  end

  def get_joined_call(calls)
    joined_call = nil
    @joined_calls.each do |joined|
      calls.each do |call|
        joined_call = joined if joined[:calls].inlude? call
      end
    end
    joined_call
  end

  def remove_joined_call(calls)
    get_joined_call(calls)[:calls] = []
  end

  def send_call(call_log)
    @call_log.translate
    response = Net::HTTP.post_form URI.parse("http://www.websequencediagrams.com/index.php"), 'style' => 'modern-blue', 'message' => @call_log.post_data
    "http://www.websequencediagrams.com/" + response.body.split("{img: \"")[1].split("\"")[0]
  end
end
