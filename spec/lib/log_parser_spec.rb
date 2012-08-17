require 'spec_helper'

describe LogParser do

  before :each do
    @file = mock("mock file")
    @parser = LogParser.new @file
  end

  describe "#timestamped?" do
    it "should return true if the line begins with a timestamp" do
      message = "[2000-01-01 00:30:45] This is timestamped"
      @parser.timestamped?(message).should == true
    end

    it "should return false if the line does not begin with a timestamp" do
      message = "This is not timestamped"
      @parser.timestamped?(message).should == false
    end
  end

  describe "#trace_message?" do
    it "should return true if the message is a trace message" do
      message = "[2000-01-01 00:30:45] TRACE Message goes here"
      @parser.trace_message?(message).should == true
    end

    it "should return false if the message is not a trace message" do
      message = "[2000-01-01 00:30:45] DEBUG This is not a trace message"
      @parser.trace_message?(message).should == false
    end
  end

end