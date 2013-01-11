require_relative "./rayo_parser"
class AhnConfigParser
  def initialize(log, ahn_log)
    @log = File.open(log, 'r')
    @ahn_log = ahn_log
    @line_number = 1
    @parser_type = nil 
    @pb_user = nil
  end

  def strip_formatting!(line)
    line.gsub!(/\e\[(\d+;?)*\]?m/, '')
    line.delete! " "
    line.delete! ":"
    line.delete! "\""
    line.delete! "\n"
  end
  
  def timestamped?(line)
    (line =~ /^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]/) == 0
  end

  def config_line?(line)
    strip_formatting! line
    (line =~ /^config/) == 0
  end

  def run 
    @line_number += 1 until config_line? @log.readline(@line_number)
    until timestamped? (line = @log.readline(@line_number)) do
      process_config line     
      @line_number += 1 
    end
    @ahn_log.save
    execute_parser
  end

  def process_config(line)
    strip_formatting! line
    config_option = line.split "="
    @ahn_log.startup_events.create(key: config_option[0], value: config_option[1])
  end

  def execute_parser
    @parser_type = @ahn_log.startup_events.where(key: "config.punchblock.platform").first.value
    @pb_user = @ahn_log.startup_events.where(key: "config.punchblock.username").first.value
    file = File.open("/Users/wdrexler/Desktop/rails.log", 'w')
    file.write @parser_type
    file.close
    RayoParser.new(@log, @ahn_log, @line_number, @pb_user).run if @parser_type == "xmpp" 
    AsteriskParser.new(@log, @ahn_log, @line_number) if @parser_type == :asterisk
    exit if @parser_type == :none || @parser_type == :freeswitch
  end
end
