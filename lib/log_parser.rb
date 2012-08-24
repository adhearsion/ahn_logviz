require 'net/http'
require 'uri'

class LogParser

  def initialize(path_to_file)
    @path = path_to_file
    @entities = {'adhearsion' => 'Adhearsion'}
    @joined_calls = []
    @log = File.open(@path)
    @event_data = ""
    @post_data = ""
    @stored_line = ""
    @line_number = 0
  end

  def start
    begin
      read_call
    rescue EOFError
      @log.close
    ensure
      prepare_results
      send_results
    end
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0
  end

  def read_call
    @call_log = CallLog.new
    first_event = nil
    while first_event == nil do
      first_event = get_event read_next_message(@stored_line)
    end
    @main_call = first_event[0][:from]
    puts @main_call
    @call_log.id = @main_call
    translate find_dial(first_event)
    current_event = first_event
    until current_event[0][:event] == "Hangup" && current_event[0][:to] == @main_call do
      current_event = get_event read_next_message(@stored_line)
      current_event = get_event read_next_message(@stored_line) while current_event.nil?
      translate find_dial(current_event)
    end
    @call_log.calls = @entities
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
        message += line unless timestamped? line
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
        to = new_joined_call from unless has_joined_call? from
        event = "Joined"

        if to
          from.each do |f|
            message_data += [{from: f, to: to, event: event}]
          end
        else
          message_data = nil
        end
      when /unjoined/
        from = get_joined_call call_id
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
        event = "Joined"

        message_data = [{from: from, to: to, event: event}]
        @main_call = from
      when /ConfbridgeLeave/
        channel = extract_channel_id_from_address message.split("Channel\"=>\"")[1].split("\"")[0]
        from = message.split("Conference\"=>\"")[1].split("\"")[0]
        to = channel
        event = "Unjoined"

        message_data = [{from: from, to: to, event: event}]
      else
        message_data = nil
      end
    when /RubyAMI::Client: \[SEND\]:/
      case message[:message]
      when /hangup/
        puts "Hangup message: #{message}"
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

  def extract_call_id_from_address(address)
    address.split("@")[0]
  end

  def extract_channel_id_from_address(address)
    address.split("/")[1].delete("-")
  end

  def new_conf_bridge(conf_name)
    @entities["#{conf_name}"] = "#{conf_name}"
    conf_name
  end

  def new_joined_call(calls = [])
    @entities["jc#{@joined_calls.length}"] = "Bridge#{@joined_calls.length + 1}"
    @joined_calls[@joined_calls.length] = {:calls => calls, :name => "Bridge#{@joined_calls.length + 1}", :ref => "jc#{@joined_calls.length}"}
    @joined_calls.last[:ref]
  end

  def new_call_ref(call_id)
    @entities["#{call_id}"] = "Call#{@entities.length}"
  end

  def get_joined_call(call_id)
    match = false
    joined_call = nil
    @joined_calls.each do |call_ref|
      call_ref[:calls].each do |call|
        if call_id == call
          match = true
        end
      end
      joined_call = call_ref[:ref] if match
    end
    joined_call
  end

  def translate(data)
    data.each do |event|
      new_call_ref event[:from] unless @entities.keys.include? event[:from]
      new_call_ref event[:to] unless @entities.keys.include? event[:to]
      @call_log.create_message time: event[:time], message: event.delete(:time)
      puts "#{@line_number}: #{event[:from]}->#{event[:to]}: #{event[:event]}\n"
      @event_data += "#{event[:from]}->#{event[:to]}: #{event[:event]}\n"
    end
  end

  private

  def has_joined_call?(calls)
    has_joined_call = false
    one_joined_call = false
    calls.each do |call|
      if get_joined_call call
        has_joined_call = true if one_joined_call
        one_joined_call = true
      end
    end
    has_joined_call
  end

  def conf_bridge_exist?(conf_name)
    @entities.keys.include? conf_name
  end

  def remove_joined_call(calls)
    @joined_calls.each do |joined|
      one_match = false
      two_match = false
      joined[:calls].each do |joined_call|
        calls.each do |call|
          if joined_call == call
            two_match = true if one_match
            one_match = true
          end
        end
      end
      @joined_calls.delete(joined) if two_match
    end
  end

  def prepare_results
    @post_data = "title Adhearsion Call #{@main_call}\n"
    @entities.each do |k, v|
      @post_data += "participant #{v} as #{k}\n"
    end
    @post_data += @event_data
  end

  def find_dial(event)
    unless event[0].nil?
      if (event[0][:event] == "Dial") && event[0][:to].nil?
        if event[0][:from] == @main_call
          puts "Finding Dial To..."
          next_event = nil
          next_event = get_event read_next_message(@stored_line) while next_event.nil?
          until next_event[0][:event] == "Ringing" do
            translate find_dial(next_event)
            next_event = nil
            next_event = get_event read_next_message(@stored_line) while next_event.nil?
          end
          event[0][:to] = next_event[0][:to]
          event += [{from: next_event[0][:to], to: next_event[0][:from], event: next_event[0][:event]}]
        else
          puts "Finding Dial To..."
          dial_to = nil
          dial_to = get_event read_next_message while dial_to.nil?
          event[0][:to] = dial_to[0][:to]
          event += [{from: dial_to[0][:to], to: dial_to[0][:from], event: dial_to[0][:event]}]
        end
      end
      event
    else
      nil
    end
  end

  def send_results
    response = Net::HTTP.post_form URI.parse("http://www.websequencediagrams.com/index.php"), 'style' => 'modern-blue', 'message' => @post_data
    puts "http://www.websequencediagrams.com/" + response.body.split("{img: \"")[1].split("\"")[0]
  end
end