require 'zlib'
module LogViz
  module Helpers
    def create_log(params)
      name = params[:name] == "" ? nil : params[:name]
      @ahn_log = AdhearsionLog.create name: name
      file_path = File.expand_path "public/uploads/#{@ahn_log.id}.log"
      FileUtils.cp params[:logfile][:tempfile].path, file_path
      @ahn_log.log = Zlib::Deflate.deflate IO.read(file_path)
      @ahn_log.save
      puts @ahn_log.errors.inspect
      LogViz::AdhearsionParser.new(file_path, @ahn_log).run
    end

    def call_view_data(call)
      @calls = [call]
      @calls.push Call.where(master_id: call.id).all
      @calls.flatten!
      @calls = get_additional_calls @calls
      events = get_events @calls
      events.flatten!
      process_events events
      assign_y_vals
      @call_count = @calls_array.length
      @event_count = @events_array.length
    end

    def process_events(events)
      y = 100
      events.each do |event|
        event_x = @call_x_mapping[event.from]
        event_y = y
        puts @y_vals.inspect
        p "PUSHING TO Y VALS OF #{event.to} AND #{event.from}"
        @y_vals[event.from] ||= []
        @y_vals[event.to] ||= []
        @y_vals[event.from].push y
        p "PUSHED TO #{event.from}"
        @y_vals[event.to].push y
        if event.from == event.to
          arrow_type = 'to_self'
          name = event.action
          ending_x = nil
          y += 40
        else
          arrow_type = nil
          name = event.action
          ending_x = @call_x_mapping[event.to]
          @y_vals[event.to].push y if @y_vals[event.to]
          y += 20
        end
        @events_array.push [event_x, event_y, arrow_type, name, ending_x]
      end
    end

    def assign_y_vals
      puts @y_vals.inspect
      @calls_array.each do |call|
        next if @y_vals[call[0]].nil?
        first_event = (@y_vals[call[0]].first || 125) - 25
        last_event = (@y_vals[call[0]].last || 125) + 25
        call.push first_event, last_event
      end
    end

    def get_additional_calls(calls)
      @ahn_log = calls.first.adhearsion_log
      @uuids = []
      calls.each do |call|
        @uuids.push call.uuid if call
      end
      puts "CALLS: #{calls.inspect}"
      calls.each do |call|
        next unless call
        CallEvent.where(call: call).all.each do |event|
          new_call = nil
          new_call = event.to unless @uuids.index(event.to)
          new_call = event.from unless @uuids.index(event.from)
          @uuids.push(new_call)  
        end
      end
      @uuids.each do |uuid|
        call = Call.first(adhearsion_log: @ahn_log, uuid: uuid)
        calls.push call unless call.nil? || calls.index(call)
      end
      calls
    end

    def get_events(calls)
      events = []
      calls.each do |call|
        events.push CallEvent.where(call: call)
      end
      events
    end

  end
end