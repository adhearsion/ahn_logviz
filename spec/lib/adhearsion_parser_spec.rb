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

    describe "#get_time" do
      it "Should return the proper time on timestamped messages" do
        message = "[2012-12-21 00:00:00] BLAH"
        @parser.get_time(message).should == DateTime.new(2012,12,21,0,0,0)
      end
    end

  end

  describe "#get_next_message" do
    before :each do
      @log = mock "Mock Log"
      @parser = AdhearsionParser.new(@log, "Random", 1, "Parameters")
    end
    
    it "should select only a trace message" do
      lines = ["[2012-12-21 00:00:00] TRACE Something::Something",
             "[2012-12-21 00:00:00] DEBUG Something::Else"]
      @log.should_receive(:readline).and_return lines[0]
      2.times do |i|
        @log.should_receive(:readline).and_return lines[i]
      end
      @parser.get_next_message.should == lines[0]
    end
  end

  describe "#new_event" do
    before :each do
      @call = Call.new start_time: DateTime.new, is_master: true, sip_address: "fake@ahnlogviz.net"
      @call_events = mock "Mock CallEvents"
      @call.stub!(:call_events).and_return @call_events
      @parser = AdhearsionParser.new("No", "Need", "For", "Params")
    end 

    it "should create a new event" do
      message = "[2012-12-21 00:00:00] A message"
      @parser.should_receive(:get_event).and_return({ from: "fake@ahnlogviz.net", to: "fake@ahnlogviz.net", event: "Hangup" })
      @call_events.should_receive(:create).with(log: message, time: DateTime.new(2012,12,21,0,0,0), from: "fake@ahnlogviz.net", to: "fake@ahnlogviz.net", event: "Hangup")
      @parser.new_event(@call, message)
    end
  end

  

end
