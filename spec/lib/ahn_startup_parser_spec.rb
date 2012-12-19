require_relative "../../lib/ahn_startup_parser"
describe AhnStartupParser do

  before :each do
    @log = mock("mock log")
    @logfile = mock("mock logfile")
    @ahn_log = mock("mock AdhearsionLog")
    File.should_receive(:open).with(@log, 'r').and_return @logfile
    @parser = AhnStartupParser.new(@log, @ahn_log)
  end

  describe "#read_platform" do

    it "should read the platform from the platform line" do
      @parser.read_platform("[33m  config.punchblock.[0m[37mplatform          [0m[33m = [0m[36m:xmpp[0m").should == :xmpp 
    end

  end

  describe "#read_punchblock_username" do

    it "should correctly grab the punchblock username from the appropriate line" do
      @parser.read_punchblock_username("\e[33mconfig.punchblock.username =      \e[34m \"fake@ahnlogviz.net\"").should == "fake@ahnlogviz.net"
    end

  end

end
