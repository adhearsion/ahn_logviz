require 'nokogiri'

class RayoParser
  def initialize(log, ahn_log, line_number)
    @log = log
    @ahn_log = ahn_log
    @line_number = line_number
    @stored_line = ""
  end

  def run
    begin
      until @log.eof? do
        @joined_calls = []
        read_next_call
      end
    rescue EOFError
      @log.close
    ensure
      @call_log.save
    end
  end

  def readable?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] TRACE/) == 0 || (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] ERROR/) == 0
  end

  def timestamped?(message)
    (message =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def read_next_call

  end

  def get_event(message)
    if readable? message
      time = message.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/).to_s
      case message
      when /Punchblock::Connections::XMPP: SENDING/
        xml = Nokogiri::XML message.split(")")[1]
        case xml
        when proc { |xml| xml.xpath("//iq") }
          event_data = process_sent_iq xml.xpath("//iq")[0]         
        else
        end
      else
      end
    end
  end

  def process_sent_iq(node)
    case node.child.name
    when "output"
      process_output_iq node
    when "input"
      process_input_iq node
    when "dial"
      process_dial_iq node
    when "join"
      process_join_iq node
    else
    end
  end

  def process_received_iq(node)
    case node.child.name
    when "joined"
      process_joined_iq node
    when "unjoined"
      process_unjoined_iq node
    else
      if node["type"] == "error"
        process_error_iq node
      else
      end
    end
  end

