require 'yaml'
require_relative './ahn_config_parser'
module LogViz
  class AdhearsionParser
    include AhnConfigParser
    def initialize(logfile, ahn_log)
      @logfile = File.open logfile
      @ahn_log = ahn_log
      @line_number = 1
      @pb_user = nil
    end

    def run
      # parse_configs if trace_line? @logfile.readline
      begin
        until @logfile.eof? do
          process_line @logfile.readline
        end
      rescue EOFError
        @logfile.close
      ensure
        @ahn_log.save
      end
    end

    def process_line(line)
      if loglevel(line) == "DEBUG"
        process_message line
      elsif loglevel(line) == "ERROR"
        #Error stuff goes here
      else
        #We're going to add support for TRACE messages later
      end
    end

    def process_message(line)
      time = DateTime.strptime(line.match(/#{timestamp}/).to_s, "[%Y-%m-%d %H:%M:%S]")
      call_uuid = line.match(/: \w{7}\-\w{3}\-\w*/).to_s
      return unless line.index("#<")
      puts "PROCESSING LINE: #{line}"
      action_hash = process_action line[line.index("#")..-1]
      action_hash['uuid'] = call_uuid.delete(": ").strip
      event_hash = { time: time, message: action_hash, log: line }
      puts event_hash.inspect
      create_event event_hash
    end

    def process_action(action_string)
      return process_action action_string.match(/reason\=#\<.*\>/).to_s if action_string.match /^\<Punchblock::Event::Complete/
      puts "PROCESSING ACTION"
      action_hash = {}
      action_string.gsub! /[\<\>]/, ''

      headers = hashify action_string.slice!(/headers.*\=\{..*\}/), "=>", true
      if action_string.match /Input::Complete/
        action = "Input Complete"
        action_string.slice!(/^[^,]* /)
      else
        action = action_string.slice!(/^[^,]* /).delete(" ").split("::")[-1]
      end
      action_hash = hashify(action_string, "=") || {}
      action_hash['action'] = action
      action_hash['headers'] = headers if headers
      puts action_hash.inspect
      action_hash
    end

    def create_event(event_hash)
      message = event_hash[:message]
      puts "SENDING EVENTPROCESSOR ##{message['action'].downcase}"
      event = EventProcessor.send message['action'].downcase.gsub(' ', '_'), message
      return unless event
      create_new_calls check_calls(event)
      new_event = @call.add_call_event CallEvent.create(from: event[:from], to: event[:to], action: message['action'], time: event_hash[:time], log: event_hash[:log]) if @call
      puts "EVENT CREATED: #{new_event.inspect}" if new_event
    end

    def check_calls(event)
      if event[:check_master]
        master = Call.first adhearsion_log: @ahn_log, uuid: event[:from]
        call = Call.first adhearsion_log: @ahn_log, uuid: event[:to]
        if master && call
          call.is_master = false
          call.master_id = master.id
        end
      end
      to_create = []
      to_call = Call.first adhearsion_log: @ahn_log, uuid: event[:to]
      from_call = Call.first adhearsion_log: @ahn_log, uuid: event[:from]
      to_create += [{ uuid: event[:from], is_master: true, master_id: nil }] unless from_call
      to_call_hash = { uuid: event[:to], is_master: false }
      to_call_hash[:master_id] = from_call.id if from_call
      to_create += [to_call_hash] unless to_call || to_call_hash[:uuid] == 'adhearsion' || event[:to] == event[:from]
      @call = from_call if from_call
      puts "CALLS TO CREATE: #{to_create.inspect}"
      to_create
    end

    def create_new_calls(call_params)
      get_master_id = true if call_params.length == 2
      master_id = nil
      call_params.each do |call_hash|
        next if call_hash[:uuid].empty?
        if call_hash[:is_master]
          @call = @ahn_log.add_call Call.create(uuid: call_hash[:uuid], is_master: true, master_id: nil)
          puts "NEW CALL CREATED: #{@call.inspect}"
          master_id = @call.id
          call = @ahn_log.add_call Call.create(uuid: 'adhearsion', is_master: false, master_id: master_id)
          puts "NEW CALL CREATED: #{call.inspect}"
        elsif master_id
          call = @ahn_log.add_call Call.create(uuid: call_hash[:uuid], is_master: false, master_id: master_id)
          puts "NEW CALL CREATED: #{call.inspect}"
        elsif call_hash[:master_id]
          call = @ahn_log.add_call Call.create(uuid: call_hash[:uuid], is_master: false, master_id: call_hash[:master_id])
          puts "NEW CALL CREATED: #{call.inspect}"
        end
      end
    end

    def hashify(string, delimiter, named_attribute = false)
      return if string.nil?
      string.delete!("\"")
      string.gsub!(/headers.*\=\{/, '').delete!("}") if named_attribute
      string.split(", ").map {|h| h1,h2 = h.split(delimiter); {h1 => h2}}.reduce :merge
    end

    def loglevel(line)
      line.split(" ")[2]
    end

    def timestamp
      "^\\[\\d{4}\\-\\d{2}\\-\\d{2} \\d{2}:\\d{2}:\\d{2}\\]"
    end

    def trace_line?(line)
      line.match /#{timestamp} TRACE/
    end

    def timestamped?(line)
      line.match /#{timestamp}/
    end
  end
end