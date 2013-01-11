require_relative "../../lib/adhearsion_parser.rb"
require 'spec_helper'

describe AdhearsionParser, focus: true do

  describe "Line identifier methods" do
    before do
      @parser = AdhearsionParser.new("This", "Data", "Is", "Fake")
    end

    describe "#readable?" do

      it "should return true on a TRACE message" do
        @parser.readable?("[2012-12-21 00:05:14] TRACE Log stuff goes here").should == true
      end
      
      it "should return true on an ERROR message" do
        @parser.readable?("[2012-12-21 00:00:00] ERROR EndOfWorldError").should == true
      end

      it "should return false on any other message" do
        @parser.readable?("[2012-12-21 00:00:00] DEBUG Debugging Mayan Calendar...").should == false 
      end

    end

    describe "#timestamped?" do

      it "should return true on a timestamped message" do
        @parser.timestamped?("[2012-12-21 00:00:00] END OF THE WORLD").should == true
      end
      
      it "should return false on a non-timestamped message" do
        @parser.timestamped?("I have no idea what time it is...").should == false
      end

    end

  end

  describe "#hungup?" do
    before :each do
      @log = mock("mock log")
      @ahn_log = AdhearsionLog.create
      @call_log = @ahn_log.call_logs.create
      @call_log.calls.create(ahn_call_id: "will@adhearsion.com", call_name: "Adhearsion")
      @call_log.calls.create(ahn_call_id: "fake@0.com", call_name: "Call 1")
      @call_log.calls.create(ahn_call_id: "fake@1.com", call_name: "Call 2")
      2.times do |i|
        sip_addr = "fake@#{i}.com"
        event = @call_log.call_events.create(log: "log goes here", time: Time.now)
        event.create_message!(to: sip_addr, from: sip_addr, event: "Hangup")
      end
      @parser = AdhearsionParser.new(@log, @ahn_log, 1, "will@adhearsion.com")
    end

    it "should mark the CallLog as hungup if all calls are hungup" do
      @parser.hungup?(@call_log).should == true
    end

    it "should mark the CallLog as active if not all calls are hungup" do
    end

  end

end
