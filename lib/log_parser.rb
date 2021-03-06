require 'net/http'
require 'uri'
require 'date'

class LogParser
  def initialize(log, ahn_log)
    @log = File.open(log, 'r')
    @ahn_log = ahn_log
    @stored_line = ""
    @line_number = 1
    @start_line = 0
    @end_line = 0
  end

  def run
    begin
    until @log.eof? do
      @joined_calls = []
      read_call
      @ahn_log.save
    end
    rescue EOFError
      @log.close
    ensure
      @call_log.save
    end
  end

  def read_call
    first_event = get_next_event
    @main_calls = [first_event[0][:from]]
    @call_log = @ahn_log.call_logs.create(:ahn_call_name => first_event[0][:from])
    call = @call_log.calls.create(:ahn_call_id => "adhearsion", :call_name => "Adhearsion")
    call.save!
    create_call_event find_dial(first_event)
    @current_event = first_event
    until calls_hungup? == true # do
      @current_event = get_next_event
      create_call_event find_dial(@current_event)
    end
    @call_log.save
  end

  def read_next_message(line = "")
    until trace_message? line do
      line = @log.readline
      @line_number += 1
    end
    @start_line = @line_number - 1
    message = line
    line = ""
    until timestamped? line do
      line = @log.readline
      @line_number += 1
      if timestamped? line
        @end_line = @line_number - 1
        @stored_line = line
      else
        message += line
      end
    end
    { :message => message, :time => DateTime.strptime(message.split("]")[0].delete("["), "%Y-%m-%d %H:%M:%S") }
  end

  def get_event(message)
    message_data = []
    case message[:message]
    when /ERROR/
      message_data = [{:from => 'adhearsion', :to => 'adhearsion', :event => 'Error'}]
    when /RECEIVING \(presence\)/
      call_id = extract_call_id_from_address message[:message].split("from=\"")[1].split("\"")[0].delete("-")
      case message[:message]
      when /offer/
        message_data = [{:from => call_id, :to => nil, :event => "Dial"}]
      when /ringing/
        message_data = [{:from => call_id, :to => call_id, :event => "Ringing"}]
        @main_calls += [call_id] if @main_calls
      when /answered/
        message_data = [{:from => call_id, :to => call_id, :event => "Answered"}]
      when /[^u][^n]joined/
        from = [call_id, message[:message].split("<joined ")[1].split(" ")[1].split("\"/>")[0].gsub("call-id=\"", '').gsub("-", '')]
        to = nil
        to = new_joined_call from if get_joined_call(from).nil?
        event = "Joined"

        if to
          from.each do |f|
            message_data += [{:from => f, :to => to, :event => event}]
          end
        else
          message_data = nil
        end
      when /unjoined/
        from = get_joined_call([call_id, ""])[:joined_call] if get_joined_call([call_id, ""])
        to = [call_id, message[:message].split("<unjoined ")[1].split(" ")[1].split("\"/>")[0].gsub("call-id=\"", '').delete("-")]
        event = "Unjoined"

        if from
          to.each do |t|
            message_data += [{:from => from, :to => t, :event => event}]
          end
          remove_joined_call to
        else
          message_data = nil
        end
      when /hangup/
        message_data = [{:from => call_id, :to => call_id, :event => "Hangup"}]
      else
        message_data = nil
      end
    when /RubyAMI::Client: \[RECV\-EVENTS\]:/
      case message[:message]
      when /Newstate/
        channel = extract_channel_id_from_address message[:message].split("Channel\"=>\"")[1].split("\"")[0]
        case message[:message]
        when /Ring/
          message_data = [{:from => channel, :to => channel, :event => "Ringing"}]
        when /\"ChannelStateDesc\"=>\"Up\"/
          message_data = [{:from => channel, :to => channel, :event => "Answered"}]
        else
          message_data = nil
        end
      when /ConfbridgeJoin/
        unless conf_bridge_exist? extract_conference_name(message[:message])
          to = new_conf_bridge extract_conference_name(message[:message])
        else
          to = extract_conference_name message[:message]
        end
        from = extract_channel_id_from_address(message[:message].split("Channel\"=>\"")[1].split("\"")[0])

        message_data = [{:from => from, :to => to, :event => "Joined"}]
        @main_calls += [from] if @main_calls
      when /ConfbridgeLeave/
        message_data = [{:from => message[:message].split("Conference\"=>\"")[1].split("\"")[0], 
                         :to => extract_channel_id_from_address(message[:message].split("Channel\"=>\"")[1].split("\"")[0]), 
                         :event => "Unjoined"}]
      when /DTMF/
        if message[:message] =~ /\"End\"=>\"Yes\"/
          channel = extract_channel_id_from_address(message[:message].split("Channel\"=>\"")[1].split("\"")[0])
          input = message[:message].split("Digit\"=>\"")[1].split("\"")[0]
          message_data = [{:from => 'adhearsion', :to => channel, :event => "Input"}]
          message_data += [{:from => channel, :to => 'adhearsion', :event => "\"#{input}\""}]
        else
          message_data = nil
        end
      else
        message_data = nil
      end
    when /RubyAMI::Client: \[SEND\]:/
      case message[:message]
      when /hangup/
        channel = extract_channel_id_from_address message[:message].split("Channel: ")[1].strip
        message_data = [{:from => channel, :to => channel, :event => "Hangup"}]
      when /originate/
        message_data = [{:from => @main_calls.last, :to => nil, :event => "Dial"}]
      else
        message_data = nil
      end
    else 
      message_data = nil
    end
    unless message_data.nil?
      message_data.each do |m|
        m[:log] = message[:message]
        m[:time] = message[:time]
      end
    end
    message_data
  end

  def find_dial(event)
    unless event[0].nil?
      if (event[0][:event] == "Dial") && event[0][:to].nil?
        next_event = get_next_event
        until next_event[0][:event] == "Ringing" do
          create_call_event find_dial(next_event)
          next_event = get_next_event
        end
        event[0][:to] = next_event[0][:to]
        event += [{:from => next_event[0][:to], :to => next_event[0][:from], :event => next_event[0][:event], :time => event[0][:time], :log => next_event[0][:log]}]
      end
      event
    else
      nil
    end
  end

  def create_call_event(event)
    event.each do |e|
      new_call_ref e[:from] if @call_log.calls.where(:ahn_call_id => e[:from]).empty?
      new_call_ref e[:to] if @call_log.calls.where(:ahn_call_id => e[:to]).empty?
      call_event = @call_log.call_events.create(:time => e[:time], :log => e[:log])
      call_event.create_message(:from => e[:from], :to => e[:to], :event => e[:event] + " (#{e[:time].strftime '%T'})")
    end
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0 || (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] ERROR/) == 0
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

  def extract_conference_name(message)
    message.split("Conference\"=>\"")[1].split("\"")[0]
  end

  def new_call_ref(call_id)
    @call_log.calls.create :ahn_call_id => "#{call_id}", :call_name => "Call#{@call_log.calls.length}"
  end

  def new_conf_bridge(conf_name)
    @call_log.calls.create :ahn_call_id => "#{conf_name}", :call_name => "#{conf_name}"
    conf_name
  end

  def conf_bridge_exist?(conf_name)
    @call_log.calls.where :ahn_call_id => conf_name
  end

  def new_joined_call(calls)
    @call_log.calls.create :ahn_call_id => "jc#{@joined_calls.length}", :call_name => "Bridge#{@joined_calls.length + 1}"
    @joined_calls += [{:joined_call => @call_log.calls.last.ahn_call_id, :calls => calls}]
    @joined_calls.last[:joined_call]
  end

  def get_joined_call(calls)
    joined_call = nil
    @joined_calls.each do |joined|
      calls.each do |call|
        joined_call = joined if joined[:calls].include? call
      end
    end
    unless joined_call.nil?
      joined_call
    else
      nil
    end
  end

  def remove_joined_call(calls)
    get_joined_call(calls)[:calls] = []
  end

  def calls_hungup?
    @main_calls.each do |call|
      if @current_event[0][:event] == "Hangup" && @current_event[0][:to] == call
        @main_calls.delete call
      end
    end
    if @main_calls.empty?
      true
    else
      false
    end
  end
end
