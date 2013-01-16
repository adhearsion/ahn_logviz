require 'spec_helper'
require_relative '../../lib/rayo_parser.rb'
describe RayoParser do
  
  before :each do
    @pb_user = "fake@ahnlogviz.net"
    @ahn_log = AdhearsionLog.create
    @log = mock "Mock Logfile"
    @parser = RayoParser.new(@log, @ahn_log, 1, @pb_user)
  end

  describe "#get_domain" do
    it "should get the domain from a jabber id" do
      @parser.get_domain("fake@ahnlogviz.net").should == "ahnlogviz.net"
    end
  end

  describe "#get_event" do
    it "Should run #process_sent_iq on a sent <iq>" do
      message = "[2012-12-21 00:00:00] TRACE SENDING (iq) <iq property1=\"value1\"/>" 
      @parser.should_receive :process_sent_iq
      @parser.get_event message 
    end

    it "Should run #process_received_iq on a received <iq>" do
      message = "[2012-12-21 00:00:00] TRACE RECEIVING (iq) <iq property1=\"value1\"/>"
      @parser.should_receive :process_received_iq
      @parser.get_event message
    end

    it "Should run #process_received_presence on a received <presence>" do
      message = "[2012-12-21 00:00:00] TRACE RECEIVING (presence) <presence from=\"someone\">"
      @parser.should_receive :process_received_presence
      @parser.get_event message
    end

    it "Should return the proper ERROR event if it encounters an ERROR line" do
      message = "[2012-12-21 00:00:00] ERROR IntruderAlert!"
      @parser.get_event(message).should == { from: @pb_user, to: @pb_user, event: "ERROR" }
    end

    it "Should return nil if the message does not apply to the filters" do
      message = "[2012-12-21 00:00:00] TRACE SENDING (something) <something/>"
      @parser.get_event(message).should == nil
    end
  end

  describe "#process_sent_iq" do
    it "should properly process a sent <join>" do
      message = Nokogiri::XML "<iq to=\"random_string@ahnlogviz.net\"><join call-id=\"random_string2\"></iq>"
      @parser.process_sent_iq(message).should == { from: "random_string@ahnlogviz.net", to: "random_string2@ahnlogviz.net", event: "Join" }
    end

    it "should send <dial>s to #process_dial" do
      message = Nokogiri::XML "<dial/>"
      @parser.should_receive :process_dial
      @parser.process_sent_iq message
    end

    it "should send <output>s to #process_output" do
      message = Nokogiri::XML "<iq><output></iq>"
      @parser.should_receive :process_output
      @parser.process_sent_iq message
    end

    it "should indicate awaiting input" do
      message = Nokogiri::XML "<iq to=\"random_string@ahnlogviz.net\"><input/></iq>"
      @parser.process_sent_iq(message).should == {from: @pb_user, to: "random_string@ahnlogviz.net",
                                         event: "Getting Input..."}
    end
  end

  describe "#process_received_presence" do
    it "should send <offer>s to #process_offer" do
      message = Nokogiri::XML "<offer/>"
      @parser.should_receive :process_offer
      @parser.process_received_presence message
    end

    it "should process <ringing> properly" do
      message = Nokogiri::XML "<presence from=\"random_string@ahnlogviz.net\" to=\"#{@pb_user}\"><ringing/></presence>"
      @parser.process_received_presence(message).should == {from: "random_string@ahnlogviz.net",
                                                            to: "random_string@ahnlogviz.net", 
                                                            event: "Ringing"} 
    end

    it "should process <answered> properly" do
      message = Nokogiri::XML "<presence from=\"random_string@ahnlogviz.net\"><answered/></presence>"
      @parser.process_received_presence(message).should == {from: "random_string@ahnlogviz.net",
                                                            to: "random_string@ahnlogviz.net",
                                                            event: "Answer"}
    end

    it "should send <input>s to #process_input" do
      message = Nokogiri::XML "<presence><input /></presence>"
      @parser.should_receive :process_input
      @parser.process_received_presence message
    end
  end

  describe "#process_dial" do
    before :each do
      @call = @ahn_log.calls.create(is_master: true, sip_address: "sip:sip@ahnlogviz.net", 
                                    ahn_call_id: "random_string@ahnlogviz.net")
    end

    it "should correctly parse a <dial>" do
      @calls = mock "Mock Calls"
      message = Nokogiri::XML "<iq><dial from=\"sip:sip@ahnlogviz.net\" to=\"sip:sip1@ahnlogviz.net\">"
      lines = ["[2012-12-21 00:00:00] TRACE RECEIVING (iq) <iq><ref id=\"random_string2\"/></iq>",
               "[2012-12-21 00:00:00] DEBUG"]
      @log.should_receive(:readline).and_return lines[0]
      2.times do |i|
        @log.should_receive(:readline).and_return lines[i]
      end
      @parser.process_dial(message).should == { from: "random_string@ahnlogviz.net",
                                                to: "random_string2@ahnlogviz.net",
                                                event: "Dial" }
      @ahn_log.calls.where(ahn_call_id: "random_string2@ahnlogviz.net", is_master: false).should_not == []
    end
  end

  describe "#process_offer" do
    it "should create a new call if the offer is to Adhearsion" do
      message = "<presence from=\"random_string@ahnlogviz.net\" to=\"#{@pb_user}\"><offer from=\"sip:fake@ahnlogviz.net\" to=\"sip_address2\"></offer></presence>"
      xml = Nokogiri::XML message
      @parser.process_offer(xml).should == { from: "random_string@ahnlogviz.net", to: @pb_user, event: "Call" }
      @ahn_log.calls.where(sip_address: "sip:fake@ahnlogviz.net", 
                           ahn_call_id: "random_string@ahnlogviz.net",
                           is_master: true).should_not == []
      @ahn_log.calls.where(sip_address: "Adhearsion",
                           ahn_call_id: @pb_user,
                           is_master: false).should_not == []
    end

    it "should not create a new call if the offer is not to Adhearsion" do
      message = "<presence from=\"random_string@ahnlogviz.net\" to=\"random_string2@ahnlogviz.net\"><offer from=\"sip:fake@ahnlogviz.net\"/></presence>"
      xml = Nokogiri::XML message
      @parser.process_offer(xml).should == nil
      @ahn_log.calls.where(ahn_call_id: "random_string@ahnlogviz.net").should == []
    end
  end

  describe "#process_input" do
    it "should process ASR matches" do
      message = "<presence from=\"random_string@ahnlogviz.net\"><complete><match><input mode=\"speech\">hello</input></match></complete>"
      xml = Nokogiri::XML message
      @parser.process_input(xml).should == { from: "random_string@ahnlogviz.net",
                                             to: "random_string@ahnlogviz.net",
                                             event: "ASR Input: \"hello\"" }
    end

    it "should process ASR nomatch" do
      xml = Nokogiri::XML "<presence from=\"random_string@ahnlogviz.net\"><complete><nomatch/></complete>"
      @parser.process_input(xml).should == { from: "random_string@ahnlogviz.net",
                                             to: "random_string@ahnlogviz.net",
                                             event: "ASR NoMatch" }
    end
  end

  describe "#process_output" do
    it "should process TTS Output" do
      xml = Nokogiri::XML "<iq to=\"random_string@ahnlogviz.net\"><output><speak>Hello</speak></output></iq>"
      @parser.process_output(xml).should == { from: @pb_user,
                                              to: "random_string@ahnlogviz.net",
                                              event: "TTS Output: \"Hello\"" }
    end

    it "should process audio file output" do
      xml = Nokogiri::XML "<iq to=\"random_string@ahnlogviz.net\"><output><speak><audio/></speak></output></iq>"
      @parser.process_output(xml).should == { from: @pb_user,
                                              to: "random_string@ahnlogviz.net",
                                              event: "Output: Audio File" }
    end
  end


end
