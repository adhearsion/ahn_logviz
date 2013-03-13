module LogViz
  module AhnConfigParser
    def strip_formatting!(line)
      line.gsub!(/\e\[(\d{1,2};?)*\]?m/, '')
      line.delete! " "
      line.delete! ":"
      line.delete! "\""
      line.delete! "\n"
    end   

    def config_line?(line)
      strip_formatting! line
      (line =~ /^config/) == 0
    end

    def parse_configs
      @line_number += 1 until config_line? @logfile.readline
      @logfile.lineno = @line_number
      until timestamped? line = @logfile.readline do
        process_config line     
        @line_number += 1 
      end
      @ahn_log.save
    end

    def process_config(line)
      strip_formatting! line
      config_option = line.split "="
      @ahn_log.startup_events.create(key: config_option[0], value: config_option[1])
    end
  end
end
