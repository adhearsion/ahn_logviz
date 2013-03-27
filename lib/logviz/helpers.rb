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
      x = 100
      @y_vals = {}
      @call_x_mapping = {}
      @events_array = []
      @calls_array = [call]
      @calls_array = get_additional_calls @calls_array
      # @calls_array.push Call.where(master_id: call.id).all
      @calls_array.flatten!
      puts "CALLS: #{@calls_array}"
      events = get_events @calls_array
      @calls_array.each do |call|
        @call_x_mapping[call.uuid] = x
        x += 200
      end
      @calls_array.map! { |call| [call.uuid] }
      puts "CALL X MAPPING: #{@call_x_mapping}"
      events.flatten!
      process_events events
      assign_y_vals
      @call_count = @calls_array.length
      @event_count = @events_array.length
    end

    def process_events(events)
      y = 100
      events.each do |event|
        if (event.to && event.from)
          if @call_x_mapping[event.from].nil?
            @call_x_mapping[event.from] = @call_x_mapping.values.last + 200
            @calls_array.push [event.from]
          end
          event_x = @call_x_mapping[event.from]
          next if event_x.nil?
          event_y = y
          puts @y_vals.inspect
          p "PUSHING TO Y VALS OF #{event.to} AND #{event.from}"
          @y_vals[event.from] ||= []        
          @y_vals[event.from].push y
          p "PUSHED TO #{event.from}"
          if event.from == event.to
            arrow_type = 'to_self'
            name = event.action
            ending_x = nil
            y += 40
          else
            if @call_x_mapping[event.to].nil?
              @call_x_mapping[event.to] = @call_x_mapping.values.last + 200
              @calls_array.push [event.to]
            end
            @y_vals[event.to] ||= []
            @y_vals[event.to].push y
            arrow_type = nil
            name = event.action
            ending_x = @call_x_mapping[event.to]
            @y_vals[event.to].push y if @y_vals[event.to]
            y += 40
          end
          @events_array.push [event_x, event_y, arrow_type, name, ending_x]
        end
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
          unless event.to == 'adhearsion' || event.from == 'adhearsion'
            new_call = event.to unless @uuids.index(event.to)
            new_call = event.from unless @uuids.index(event.from)
          end
          @uuids.push(new_call)  
        end
      end
      @uuids.uniq!
      @uuids.each do |uuid|
        call = Call.first(adhearsion_log: @ahn_log, uuid: uuid)
        calls.push call unless call.nil? || calls.index(call)
      end
      calls
    end

    def get_events(calls)
      events = []
      events.push CallEvent.where(call: calls).order(:time).all
      events
    end

  end
end