require_relative "../../lib/ahn_config_parser"
describe AhnConfigParser do

  before :each do
    @log = mock("mock log")
    @logfile = mock("mock logfile")
    @ahn_log = mock("mock AdhearsionLog")
    File.should_receive(:open).with(@log, 'r').and_return @logfile
    @parser = AhnConfigParser.new(@log, @ahn_log)
  end

  describe "#strip_formatting!" do
    it "should strip color formatting and whitespace from config lines" do
      line = "\e[34m     config.punchblock.\e[32mpassword  = \e[31m\"Stoptryingtostealmypassword\""
      @parser.strip_formatting! line
      line.should == "config.punchblock.password=\"Stoptryingtostealmypassword\""
    end
  end
  
  describe "#config_line?" do
    it "should properly identify a config line" do
      @parser.config_line?("\e[34m     config.punchblock.\e[32mpassword  = \e[31m\"Stoptryingtostealmypassword\"").should == true
    end

    it "should return false when the line is not a config line" do
      @parser.config_line?("I am not a config option, go away").should == false
    end
  end 

  describe "#process_config" do
    before :each do
      @startup_events = mock("mock StartupEvents")
    end
    
    it "should correctly parse configs" do
      line = @parser.strip_formatting! "\e[34m     config.punchblock.\e[32mpassword  = \e[31m\"Stoptryingtostealmypassword\""
      @ahn_log.should_receive(:startup_events).and_return @startup_events
      @startup_events.should_receive(:create).with(key: "config.punchblock.password", value: "\"Stoptryingtostealmypassword\"")
      @parser.process_config line
    end

  end

end
