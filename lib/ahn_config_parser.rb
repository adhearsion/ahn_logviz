class AhnStartupParser
  def initialize(log, ahn_log)
    @log = File.open(log, 'r')
    @ahn_log = ahn_log
    @stored_line = ""
    @line_number = 1
    @start_line = 0
    @end_line = 0
    @parser_type = nil 
    @pb_user = nil
  end

  def strip_formatting!(line)
    line.gsub!(/\e\[(\d+;?)*\]?m/, '')
    line.delete! " "
  end

  def config_line?(line)
    strip_formatting! line
    (line =~ /^config/) == 0
  end

  def read_startup_events
    while config_line? (line = @log.readline(@line_number)
      process_config line     
      @line_number += 1 
    end
    @line_number -= 1 #The last line read was not config
    @ahn_log.save
    execute_parser
  end

  def process_config(line)
    config_option = line.split "="
    case config_option[0]
    when /config\.punchblock\.platform/
      @parser_type = config_option[1].to_sym
    when /config\.punchblock\.username/
      @pb_user = config_option[1]
    end
    @ahn_log.startup_events.create(key: config_option[0], value: config_option[1])
  end

  def execute_parser
    RayoParser.new(@log, @ahn_log, @line_number) if @parser_type == :xmpp
    AsteriskParser.new(@log, @ahn_log, @line_number) if @parser_type == :asterisk
    exit if @parser_type == :none || @parser_type == :freeswitch
  end
end
