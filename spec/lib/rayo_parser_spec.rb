require 'spec_helper'
require_relative '../../lib/rayo_parser.rb'
describe RayoParser do
  
  before :each do
    @pb_user = "fake@ahnlogviz.net"
    @jid1 = "random_string@ahnlogviz.net"
    @jid2 = "random_string2@ahnlogviz.net"
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
      call = @ahn_log.calls.create(ahn_call_id: @pb_user)
      message = "[2012-12-21 00:00:00] ERROR IntruderAlert!"
      @parser.get_event(message).should == { call: call, event: { from: @pb_user, to: @pb_user, event: "ERROR" } }
    end

    it "Should return nil if the message does not apply to the filters" do
      message = "[2012-12-21 00:00:00] TRACE SENDING (something) <something/>"
      @parser.get_event(message).should == nil
    end
  end

  describe "#process_sent_iq" do
    it "should properly process a sent <join>" do
      event = { from: @jid1, to: @jid2, event: "Join" }
      call = @ahn_log.calls.create ahn_call_id: @jid1 
      message = Nokogiri::XML "<iq to=\"#{@jid1}\"><join call-id=\"random_string2\"></iq>"
      @parser.process_sent_iq(message).should == { event: event, call: call }
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
      master_call = @ahn_log.calls.create ahn_call_id: @jid1
      call = @ahn_log.calls.create ahn_call_id: @pb_user, master_call_id: master_call.id
      event = { from: @pb_user, to: @jid1, event: "Getting Input..." }
      message = Nokogiri::XML "<iq to=\"#{@jid1}\"><input/></iq>"
      @parser.process_sent_iq(message).should == { call: call, event: event }
    end
  end

  describe "#process_received_presence" do
    before :each do 
      @call = @ahn_log.calls.create ahn_call_id: @jid1
    end

    it "should send <offer>s to #process_offer" do
      message = Nokogiri::XML "<offer/>"
      @parser.should_receive :process_offer
      @parser.process_received_presence message
    end

    it "should process <ringing> properly" do
      event = { from: @jid1, to: @jid1, event: "Ringing" }
      message = Nokogiri::XML "<presence from=\"#{@jid1}\" to=\"#{@pb_user}\"><ringing/></presence>"
      @parser.process_received_presence(message).should == {event: event, call: @call}
    end

    it "should process <answered> properly" do
      event = { from: @jid1, to: @jid1, event: "Answered" }
      message = Nokogiri::XML "<presence from=\"#{@jid1}\"><answered/></presence>"
      @parser.process_received_presence(message).should == {event: event, call: @call}
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
      event = {from: @jid1, to: @jid2, event: "Dial"}
      message = Nokogiri::XML "<iq><dial from=\"sip:sip@ahnlogviz.net\" to=\"sip:sip1@ahnlogviz.net\">"
      lines = ["[2012-12-21 00:00:00] TRACE RECEIVING (iq) <iq><ref id=\"random_string2\"/></iq>",
               "[2012-12-21 00:00:00] DEBUG"]
      @log.should_receive(:readline).and_return lines[0]
      2.times do |i|
        @log.should_receive(:readline).and_return lines[i]
      end
      @parser.process_dial(message).should == { event: event, call: @call }
      @ahn_log.calls.where(ahn_call_id: @jid2, is_master: false).should_not == []
    end
  end

  describe "#process_offer" do
    it "should create a new call if the offer is to Adhearsion" do
      event = { from: @jid1, to: @pb_user, event: "Call" }
      message = "<presence from=\"#{@jid1}\" to=\"#{@pb_user}\"><offer from=\"sip:fake@ahnlogviz.net\" to=\"sip_address2\"></offer></presence>"
      xml = Nokogiri::XML message
      @parser.process_offer(xml).should == { event: event, call: @ahn_log.calls.where(ahn_call_id: @jid1).first}
      @ahn_log.calls.where(sip_address: "sip:fake@ahnlogviz.net", 
                           ahn_call_id: @jid1,
                           is_master: true).should_not == []
      @ahn_log.calls.where(sip_address: "Adhearsion",
                           ahn_call_id: @pb_user,
                           is_master: false).should_not == []
    end

    it "should not create a new call if the offer is not to Adhearsion" do
      message = "<presence from=\"random_string@ahnlogviz.net\" to=\"random_string2@ahnlogviz.net\"><offer from=\"sip:fake@ahnlogviz.net\"/></presence>"
      xml = Nokogiri::XML message
      @parser.process_offer(xml).should == {event: nil, call: nil}
      @ahn_log.calls.where(ahn_call_id: "random_string@ahnlogviz.net").should == []
    end
  end

  describe "#process_input" do
    before :each do 
      @event = { from: @jid1, to: @pb_user}
      @call = @ahn_log.calls.create ahn_call_id: @jid1
    end
    it "should process ASR matches" do
      @event[:event] = "ASR Input: \"hello\""
      message = "<presence from=\"random_string@ahnlogviz.net\"><complete><match><input mode=\"speech\">hello</input></match></complete>"
      xml = Nokogiri::XML message
      @parser.process_input(xml).should == { event: @event, call: @call }
    end

    it "should process ASR nomatch" do
      @event[:event] = "ASR NoMatch"
      xml = Nokogiri::XML "<presence from=\"random_string@ahnlogviz.net\"><complete><nomatch/></complete>"
      @parser.process_input(xml).should == { event: @event, call: @call}
    end
  end

  describe "#process_output" do
    before :each do
      @event = { from: @pb_user, to: @jid1 }
      master_call = @ahn_log.calls.create ahn_call_id: @jid1 
      @call = @ahn_log.calls.create ahn_call_id: @pb_user, is_master: false, master_call_id: master_call.id
    end
    it "should process TTS Output" do
      @event[:event] = "TTS Output: \"Hello\""
      xml = Nokogiri::XML "<iq to=\"#{@jid1}\"><output><speak>Hello</speak></output></iq>"
      @parser.process_output(xml).should == { call: @call, event: @event }
    end

    it "should process audio file output" do
      @event[:event] = "Output: Audio File"
      xml = Nokogiri::XML "<iq to=\"random_string@ahnlogviz.net\"><output><speak><audio/></speak></output></iq>"
      @parser.process_output(xml).should == { call: @call, event: @event }
    end
  end


end
