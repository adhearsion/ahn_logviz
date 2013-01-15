require_relative "../../lib/ahn_config_parser"
require_relative "../../lib/rayo_parser"
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
      line.should == "config.punchblock.password=Stoptryingtostealmypassword"
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
      line = "\e[34m     config.punchblock.\e[32mpassword  = \e[31m\"Stoptryingtostealmypassword\""
      @ahn_log.should_receive(:startup_events).and_return @startup_events
      @startup_events.should_receive(:create).with(key: "config.punchblock.password", value: "Stoptryingtostealmypassword")
      @parser.process_config line
    end
  end

  describe "#run" do
    before do
      allow_message_expectations_on_nil
      @lines = ["config.punchblock.username = \"fake@ahnlogviz.net\"", "config.punchblock.platform = :xmpp", "[2012-12-21 00:00:00] TRACE Adhearsion::DoesItsThing"]
      @ahn_log.stub!(:startup_events).and_return @startup_events
      @startup_events.stub!(:create)
    end

    it "should read until there is no longer a config line" do
      @logfile.should_receive(:readline).with(1).and_return @lines[0]
      3.times do |i|
        @logfile.should_receive(:readline).with(i+1).and_return @lines[i]
      end
      @parser.should_receive(:process_config).twice
      @ahn_log.should_receive(:save)
      @parser.should_receive(:execute_parser)
      @parser.run
    end
    
    it "should pass the correct information to the parser" do
      @rayo_parser = mock "Mock Rayo Parser"
      @logfile.should_receive(:readline).and_return @lines[0]
      3.times do |i|
        @logfile.should_receive(:readline).and_return @lines[i]
      end
      @startup_events.should_receive(:where).and_return @startup_events
      @startup_events.should_receive(:first).and_return @startup_events
      @startup_events.should_receive(:value).and_return "xmpp"
      @startup_events.should_receive(:where).and_return @startup_events 
      @startup_events.should_receive(:first).and_return @startup_events
      @startup_events.should_receive(:value).and_return "fake@ahnlogviz.net"
      @ahn_log.should_receive(:save)
      RayoParser.should_receive(:new).with(@logfile, @ahn_log, 3, "fake@ahnlogviz.net").and_return @rayo_parser 
      @rayo_parser.should_receive :run
      @parser.run
    end

  end

end
