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
      calls = Call.where(master_id: call.id).all
      puts calls.inspect
      calls.unshift call
      @calls_array = []
      @call_x_mapping = {}
      @y_vals = {}
      x = 100
      events = []
      @events_array = []
      calls.each do |call| 
        @calls_array.push [call.uuid]
        events.push call.call_events
        @call_x_mapping[call.uuid] = x
        @y_vals[call.uuid] = []
        x += 200
      end
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
        @y_vals[event.from].push y if @y_vals[event.from]
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
      @calls_array.each do |call|
        first_event = @y_vals[call[0]].first - 25
        last_event = @y_vals[call[0]].last + 25
        call.push first_event, last_event
      end
    end

  end
end