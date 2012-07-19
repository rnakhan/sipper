require 'sip_test_case'
require 'flexmock'


class TestSession < SipTestCase

  include FlexMock::TestCase
  
  def setup
    super
    @sid = SipperConfigurator[:ShowSessionIdInMessages]
    SipperConfigurator[:ShowSessionIdInMessages] = false
    ip = "127.0.0.1"
    port = 5060
    @rip = ip
    @rp = port+1
    @t1 = Transport::UdpTransport.instance(ip, port)
    @t1.start_transport
    @s = Session.new @t1, @rip, @rp  
  end
  
  def test_new
    assert_equal(@t1, @s.transport)
    assert_equal(@rp, @s.rp)
  end

  def test_bad_new
    #assert_raise(ArgumentError) {Session.new nil, @rip, @rp}
    #assert_raise(ArgumentError) {Session.new @t1, nil, @rp}
    #assert_raise(ArgumentError) {Session.new @t1, @rip, nil}
  end
  
  def test_attr
    assert_nil(@s[:key])
    @s[:key] = "hello"
    assert_equal("hello", @s[:key])
    @s[:key] = "bye"
    assert_equal("bye", @s[:key])
  end
  
    
  
  def test_subsequent_first
    assert_raise(RuntimeError){@s.create_subsequent_request("bye")}
  end
   
  def test_response_first
    assert_raise(RuntimeError){@s.create_response(200, "OK")}
  end
  
  def test_mock_send
    send_initial_using_mock_transport
    assert_equal("Sipper <sip:sipper@127.0.0.1:5060>;tag=2", @s.local_uri)
    assert_equal("Sut <sip:sut@127.0.0.1:5061>", @s.remote_uri)
    
    r = Response.new(200)
    r.from = "sip:sipper@codepresso.com"
    r.contact = "sip:sipper@codepresso.com"
    r.to = "sip:goblet@codepresso.com"
    r.cseq = "1 MESSAGE"
    @s.send(r)
    assert_equal("<sip:goblet@codepresso.com>", @s.local_uri)
    assert_equal("<sip:sipper@codepresso.com>", @s.remote_uri)
   
    # commenting it as we can have a nil transport now
    #@s.transport = nil
    #assert_raise(StandardError) {@s.send(r)}
     
    r = "Hello"
    assert_raise(ArgumentError) {@s.send(r)}
  end
  
  def test_send_msg
    ex = []
    ex << File.new(File.join(File.dirname(__FILE__), "gold.txt")).readlines.map{|x| x.sub(/_PID_/, Process.pid.to_s ).chomp}.sort
    ex[0].insert(0,"")
    ex << File.new(File.join(File.dirname(__FILE__), "gold_res.txt")).readlines.map{|x| x.sub(/_PID_/, Process.pid.to_s ).chomp}.sort
    ex[1].insert(0,"")
    ex << File.new(File.join(File.dirname(__FILE__), "gold_sub.txt")).readlines.map{|x| x.sub(/_PID_/, Process.pid.to_s ).chomp}.sort
    ex[2].insert(0,"")
    r = Request.create_initial("invite", "sip:nasir@agnity.com", :p_asserted_identity=>"sip:nina@home.com")
    r.test_header = "test"
    r.test_header = nil
    r.via = "SIP/2.0/UDP 127.0.0.1:5061;branch=z9hG4bK-1-0-1"
    th2 = Thread.new do 
      s = UDPSocket.new
      s.bind(@rip, @rp)
      (0..2).each do |i|
        IO.select([s])
        x = s.recvfrom_nonblock(1500)[0]
        assert_equal(ex[i], x.split("\n").map{|y| y.strip}.sort)
      end
      s.close
    end
    @s.send(r)
    assert_not_nil(@s.call_id)
    assert_not_nil(@s.our_contact)
    _res = @s.create_response(200, "OK", r)
    _res.via = "SIP/2.0/UDP 127.0.0.1:5061;branch=z9hG4bK-1-0-1"
    @s.send _res
    _req = @s.create_subsequent_request("update")
    _req.via = "SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-2-0-2"
    @s.send _req
    th2.join
  end
  
  
  def test_create_subsequent
    assert_raise(RuntimeError) {@s.create_subsequent_request("invite")}
    send_initial_using_mock_transport
    k = @s.local_cseq
    r = @s.create_subsequent_request("info")
    assert_equal(k+1, @s.local_cseq ) 
    assert_equal("INFO", r.method)
  end
  
  def test_response
    send_initial_using_mock_transport
    assert_raise(RuntimeError) {@s.create_response(200, "OK")}
    rq = @s.create_subsequent_request("info")
    rs = @s.create_response(200, "OK", rq)
    [:call_id, :cseq, :via, :from].each do |m|
      assert_equal(rq.send(m), rs.send(m), "was testing #{m}")
    end
  end
  
  def test_non_sip
    assert_raise(ArgumentError) {@s.send("hello")}
    assert_raise(ArgumentError) {@s.send(Message.new)} 
  end
  
  def test_receive_request
   r = Request.new("invite", "sip:nasir@sipper.com", :call_id => "1-3332@127.0.0.1",
                     :contact => "<sip:127.0.0.1:5060;transport=UDP>",
                     :cseq => "1 INVITE", :from => "Sipper <sip:sipper@127.0.0.1:5060>;tag=1",
                     :to => "Sut <sip:sut@127.0.0.1:5061>", 
                     :via => "SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1",
                     :max_forwards => "70") 
   c = FlexMock.new
   c.should_receive(:on_request).with_any_args.and_return(true)
   c.should_receive(:name).and_return("TestSessionController")
   @s.controller = c
   assert_nothing_raised { @s.on_message(r) }
   assert_equal(r, @s.irequest)
   assert_equal("1", @s.remote_tag)
   assert_equal(r.to.to_s, @s.local_uri)
   assert_equal(r.from.to_s, @s.remote_uri)
   assert_equal("sip:127.0.0.1:5060;transport=UDP", @s.remote_target)
  end
  
  def test_receive_response
    r = _create_dummy_response
    assert_nothing_raised { @s.on_message(r) }
    assert_equal(r, @s.iresponse)
    assert_equal("sip:127.0.0.1:5060;transport=UDP", @s.remote_target)
  end
  
  def test_receive_wrong_sent_by_response
    orig = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance] = 'strict'
    r = _create_dummy_response
    r.via = "SIP/2.0/UDP 127.0.0.1:5061;branch=z9hG4bK-1-0-1"  # change port
    @s.on_message(r)
    assert_nil(@s.iresponse)
    r.via = "SIP/2.0/UDP 127.0.0.2:5060;branch=z9hG4bK-1-0-1"  # change ip
    @s.on_message(r)
    assert_nil(@s.iresponse)
    r.via = "SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1"  # change port
    @s.on_message(r)
    assert_equal(r, @s.iresponse)  # verify correct
    SipperConfigurator[:ProtocolCompliance] = orig
  end
  
  
  def test_invalidate
    SessionManager.clean_all
    send_initial_using_mock_transport
    assert_equal(@s, SessionManager.find_session(@s.call_id, @s.local_tag, @remote_tag))
    @s.invalidate(true)
    assert_nil(SessionManager.find_session(@s.call_id, @s.local_tag, @remote_tag))
  end
  
  def test_record
    assert_nothing_raised { 
      @s.do_record("test message")
      @s.invalidate(true)
    }
  end
  
  def test_cancel_creation
    assert_raise(RuntimeError) { @s.create_cancel }
    send_initial_using_mock_transport
    c = nil
    assert_nothing_raised { c = @s.create_cancel }
    assert_equal("CANCEL", c.method)
    assert_equal(@s.call_id, c.call_id.to_s)
    assert_equal(@s.our_contact, c.contact.to_s)
    assert_equal("sip:nasir@sipper.com", c.uri.to_s)
  end
  
  def test_send_cancel_on_response
    send_initial_using_mock_transport
    @s.set_session_record("msg-info")
    @s.create_and_send_cancel_when_ready
    @s.do_record("cancel created but not sent")
    r = _create_dummy_response
    @s.on_message(r)
    @s.invalidate(true)
    #todo DRY
    neutral_files = Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*_neutral")).sort 
    recording = SessionRecorder.load(neutral_files[0]).get_recording
    record_idx = 0
    expectation = ["! cancel_created_but_not_sent", "< 180", "> CANCEL"]
    expectation.each do |msg|
      assert_equal(msg, recording[record_idx])
      record_idx += 1
    end
  end
  
  def test_transaction_config
    orig = SipperConfigurator[:SessionTxnUsage]
    SipperConfigurator[:SessionTxnUsage] = {:use_transactions=>false}
    s = Session.new @t1, @rip, @rp
    assert_equal(false, s.use_transactions)
    SipperConfigurator[:SessionTxnUsage] = {:use_transactions=>true}
    s = Session.new @t1, @rip, @rp
    assert(s.use_transactions)
    SipperConfigurator[:SessionTxnUsage] = {:use_transactions=>true, :use_ict=>false, :use_nict=>true, :use_ist=>false, :use_nist=>true}
    s = Session.new @t1, @rip, @rp
    assert(!s.use_ict)
    assert(s.use_nict)
    assert(!s.use_ist)
    assert(s.use_nist)
    SipperConfigurator[:SessionTxnUsage] = orig  # restore config
  end
  
  def _create_dummy_response
    r = Response.new(180, "Ringing", 
         :call_id => "1-3332@127.0.0.1",
         :contact => "<sip:127.0.0.1:5060;transport=UDP>",
         :cseq => "1 INVITE", :from => "Sipper <sip:sipper@127.0.0.1:5060> ;tag=1",
         :to => "Sut <sip:sut@127.0.0.1:5061>", 
         :via => "SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1")
    c = FlexMock.new
    c.should_receive(:on_response).with_any_args.and_return(true)
    c.should_receive(:name).and_return("TestSessionController")
    c.should_receive(:specified_transport).and_return(nil)
    @s.controller = c
    r
  end
  
  def send_initial_using_mock_transport
    # method, r-uri...
    r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_asserted_identity=>"sip:nina@home.com")
    r.via = "SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1"
    t = FlexMock.new
    t.should_receive(:send).with_any_args
    t.should_receive(:ip).and_return("127.0.0.1")
    t.should_receive(:port).and_return("5060")
    t.should_receive(:tid).and_return("UDP")
    @s.transport = t
    @s.send(r)
  end
  
  
  def teardown
   @t1.stop_transport if @t1.running
   SipperUtil::Counter.instance.reset
   Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*_neutral")).each {|f| File.delete(f)}
   SipperConfigurator[:ShowSessionIdInMessages] = @sid
   super
  end
  
  private :send_initial_using_mock_transport, :_create_dummy_response
  
end
