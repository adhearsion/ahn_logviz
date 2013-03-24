class EventProcessor
  class << self
    def offer(message)
      puts "PROCESSING OFFER #{message.inspect}"
      if message['uuid'].empty? || message['uuid'].nil?
        { from: message['call_id'].strip, to: 'adhearsion', new_call: true }
      else
        { from: message['uuid'], to: message['call_id'].strip, new_call: true }
      end
    end

    def dial(message)
      nil
    end

    def ringing(message)
      { from: message['uuid'], to: message['uuid'] }
    end

    def answer(message)
      { from: message['uuid'], to: message['uuid'] }
    end

    def join(message)
      { from: message['call_id'].strip, to: message['uuid'], check_master: true }
    end

    def unjoined(message)
      { from: message['target_call_id'].strip, to: message['call_id'].strip}
    end

    def input(message)
      { from: 'adhearsion', to: message['uuid'] }
    end

    def input_complete(message)
      { from: message['uuid'], to: 'adhearsion', append_action: message['interpretation'] }
    end

    def output(message)
      { from: 'adhearsion', to: message['uuid'] }
    end

    def hangup(message)
      { from: message['uuid'], to: message['uuid'] }
    end

    def method_missing(method, *args)
      nil
    end
  end
end