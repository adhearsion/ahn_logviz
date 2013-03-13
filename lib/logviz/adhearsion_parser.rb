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
      @events_lookup = YAML.load_file 'config/actions.yml'
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
      call_uuid = line.match(/: \w{7}\-\w{3}\-\w{12,13}/).to_s
      return unless line.index("#<")
      puts "PROCESSING LINE: #{line}"
      action_hash = process_action line[line.index("#")..-1]
      action_hash['uuid'] = call_uuid.delete(": ").chomp '\n'
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
      if action_string.match /Complete/
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
      return unless @events_lookup.has_key? event_hash[:message]['action']
      message = event_hash[:message]
      event = message['action']
      @action_lookup = @events_lookup[event]
      event += ": #{message[@action_lookup['value']]}" if !!@action_lookup['value']

      if event == 'Offer'
        message['call_id'].chomp!
        @call = Call.first(adhearsion_log_id: @ahn_log.id, uuid: message['uuid']) || create_new_call(message)
        if @call.is_master
          from = message['call_id']
          to   = 'adhearsion'
        else
          from = message['uuid']
          to   = message['call_id']
        end
      else
        @call = Call.first(adhearsion_log_id: @ahn_log.id, uuid: message['uuid']) || create_new_call(message)
        from = message[@action_lookup['from']] || @action_lookup['from']
        to = message[@action_lookup['to']] || @action_lookup['to']
      end
      event = @call.add_call_event CallEvent.create(action: event, from: from,
       to: to, time: event_hash[:time], log: event_hash[:log])
      puts "EVENT CREATED: #{event.inspect}"
      @call.save
    end

    def create_new_call(message)
      is_master = message['uuid'].empty? || (Call.first(adhearsion_log: @ahn_log, uuid: message['uuid']).nil? && Call.first(adhearsion_log: @ahn_log, uuid: message[@action_lookup['to']]).nil?)
      puts "MASTER: #{is_master}"
      call_id = message['call_id'] || message['uuid']
      sip_address = is_master ? message['from'] : message['to'] if message['action'] == "Offer"
      master_call = Call.first(adhearsion_log: @ahn_log, uuid: message['uuid']) || Call.first(adhearsion_log: @ahn_log, uuid: message[@action_lookup['to']])
      master_id = master_call.id if master_call
      call = @ahn_log.add_call Call.create(sip_address: sip_address, uuid: message['call_id'], is_master: is_master,
       master_id: master_id)
      call.save
      puts "MAIN CALL: #{call.errors.inspect}"
      puts "MAIN CALL: #{call.valid?}"
      puts "MAIN CALL: #{call.inspect}"
      if is_master
        @ahn_log.add_call Call.create(sip_address: 'Adhearsion', uuid: 'adhearsion', is_master: false,
          master_id: call.id)
      end
      call
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