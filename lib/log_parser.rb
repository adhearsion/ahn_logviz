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
  end

  def start
    read_call
    prepare_results
    send_results
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def trace_message?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0
  end

  def read_call
    first_event = get_event read_next_message while first_event == nil
    @main_call = first_event[0][:from]
    puts @main_call
    translate find_dial(first_event)
    current_event = [{}]
    until current_event[0][:event] == "Hangup" && current_event[0][:to] == @main_call do
      current_event = get_event read_next_message
      current_event = get_event read_next_message while current_event.nil?
      translate find_dial(current_event)
    end
  end

  def read_next_message
    line = ""
    line = @log.readline until trace_message? line
    message = line
    line = @log.readline
    until timestamped? line do
      message += line unless timestamped? line
      line = @log.readline
    end
    message
  end

  def get_event(message)
    message_data = []
    case message
    when /RECEIVING \(presence\)/
      call_id = extract_call_id_from_address message.split(" ")[7].delete("\"").gsub("from=", '').delete("-")
      case message
      when /offer/
        from = call_id
        to = nil
        event = "Dial"

        message_data = [{from: from, to: to, event: event}]
      when /ringing/
        from = nil
        to = call_id
        event = "Ringing"

        message_data = [{from: from, to: to, event: event}]
      when /answered/
        from = call_id
        to = call_id
        event = "Answered"

        message_data = [{from: from, to: to, event: event}]
      when /[^u][^n]joined/
        from = [call_id, message.split("<joined ")[1].split(" ")[1].split("\"/>")[0].gsub("call-id=\"", '').gsub("-", '')]
        to = new_joined_call from
        event = "Joined"

        from.each do |f|
          message_data += [{from: f, to: to, event: event}]
        end

      when /unjoined/
        from = get_joined_call call_id
        to = [call_id, message.split("<unjoined ")[1].split(" ")[1].split("\"/>")[0].gsub("call-id=\"", '').delete("-")]
        event = "Unjoined"

        to.each do |t|
          message_data += [{from: from, to: t, event: event}]
        end

      when /end/
        from = call_id
        to = call_id
        event = "Hangup"

        message_data = [{from: from, to: to, event: event}]
      else
        message_data = nil
      end
    else 
      message_data = nil
    end
    puts "#{message_data}"
    message_data
  end

  def extract_call_id_from_address(address)
    address.split("@")[0]
  end

  def new_joined_call(calls = [])
    @entities["jc#{@joined_calls.length}"] = "JoinedCall#{@joined_calls.length + 1}"
    @joined_calls[@joined_calls.length] = {:calls => calls, :name => "JoinedCall#{@joined_calls.length + 1}", :ref => "jc#{@joined_calls.length}"}
    @joined_calls.last[:ref]
  end

  def new_call_ref(call_id)
    @entities["#{call_id}"] = "Call#{@entities.length + 1}"
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
      new_call_ref event[:to] unless @entities.keys.include? event[:to]
      new_call_ref event[:from] unless @entities.keys.include? event[:from]
      puts "#{event[:from]}->#{event[:to]}: #{event[:event]}\n"
      @event_data += "#{event[:from]}->#{event[:to]}: #{event[:event]}\n"
    end
  end

  private

  def prepare_results
    @post_data = "title Adhearsion Call #{@main_call}\n"
    @entities.each do |k, v|
      @post_data += "participant #{v} as #{k}\n"
    end
    @post_data += @event_data
  end

  def find_dial(event)
    if (event[0][:event] == "Dial") && event[0][:to].nil?
      puts "Finding Dial To..."
      dial_to = nil
      dial_to = get_event read_next_message while dial_to.nil?
      event[0][:to] = dial_to[0][:to]
      event += [{from: dial_to[0][:to], to: dial_to[0][:to], event: "Ringing"}]
    end
    event
  end

  def send_results
    response = Net::HTTP.post_form URI.parse("http://www.websequencediagrams.com/index.php"), 'style' => 'modern-blue', 'message' => @post_data
    puts response
  end
end