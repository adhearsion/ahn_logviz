require_relative "../../lib/ahn_config_parser"
describe AhnConfigParser do

  before :each do
    @log = mock("mock log")
    @logfile = mock("mock logfile")
    @ahn_log = mock("mock AdhearsionLog")
    File.should_receive(:open).with(@log, 'r').and_return @logfile
    @parser = AhnConfigParser.new(@log, @ahn_log)
  end

end
