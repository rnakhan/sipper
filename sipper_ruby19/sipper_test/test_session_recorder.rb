require 'sip_test_case'
require 'flexmock'
require 'session_recorder'

class TestSessionRecorder < SipTestCase
  include FlexMock::TestCase
  
  def setup
    SipperConfigurator[:SessionRecordPath] = File.join(File.dirname(__FILE__),"..", "sipper", "logs")
  end
  
  def test_create_and_record
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:p_session_record).and_return("msg-info")
    m.should_receive(:[]).with_any_args.and_return(true)
    m.should_receive(:class).and_return(Request)
    m.should_receive(:method).and_return("INVITE") 
    sr = SessionRecorder.create_and_record(nil, m, nil, "in")
    sr.save 
    assert_equal("< INVITE", get_in_recording.get_recording[0])
    teardown
    sr = SessionRecorder.create_and_record(nil, m, nil, "out")
    sr.record("in", m)
    sr.save 
    assert_equal("> INVITE", get_out_recording.get_recording[0])
    assert_equal("< INVITE", get_out_recording.get_recording[1])
  end
  
  def test_with_external_io
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:p_session_record).and_return("msg-info")
    m.should_receive(:[]).with_any_args.and_return(true)
    m.should_receive(:class).and_return(Response)
    m.should_receive(:code).and_return(200) 
    @rio = StringIO.new
    sr = SessionRecorder.create_and_record(@rio, m, nil, "out")
    sr.record("in", m)
    sr.save 
    recording = get_out_recording
    assert_equal("> 200", recording.get_recording[0])
    assert_equal("< 200", recording.get_recording[1])
  end
    
  def test_with_config_level
    assert_nil(SipperConfigurator[:SessionRecord])
    SipperConfigurator[:SessionRecord] = "msg-info"
    assert_not_nil(SipperConfigurator[:SessionRecord])
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:class).and_return(Request)
    m.should_receive(:method).and_return("INVITE")
    m.should_receive(:[]).with_any_args.and_return(false)
    sr = SessionRecorder.create_and_record(nil, m, nil, "in")
    sr.record("neutral", m)
    sr.save 
    assert_equal("< INVITE", get_in_recording.get_recording[0])
    assert_equal("! INVITE", get_in_recording.get_recording[1])
    SipperConfigurator[:SessionRecord] = nil
  end
  
  def test_debug_level
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:p_session_record).and_return("msg-debug")
    m.should_receive(:[]).with_any_args.and_return(true)
    m.should_receive(:class).and_return(Request)
    m.should_receive(:method).and_return("INVITE") 
    m.should_receive(:to_s).and_return("INVITE sip:nasir@agnity.com SIP/2.0
Contact: <sip:127.0.0.1:5060;transport=UDP>
P-Asserted-Identity: sip:nina@home.com
Max-Forwards: 70
Call-Id: 1-_PID_@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1
From: Sipper <sip:sipper@127.0.0.1:5060>;tag=1
To: Sut <sip:sut@127.0.0.1:5061>
Cseq: 1 INVITE
Content-Length: 0")
    sr = SessionRecorder.create_and_record(nil, m, nil, "in")
    sr.save 
    assert_equal("< INVITE sip:nasir@agnity.com SIP/2.0", get_in_recording.get_recording[0][0..36])
    assert_equal("< INVITE", get_in_recording.get_info_only_recording[0])
  end
  
  def test_debug_non_sip
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:to_s).and_return("This is a non SIP message")
    SipperConfigurator[:SessionRecord] = "msg-debug"
    m.should_receive(:[]).with_any_args.and_return(false)
    sr = SessionRecorder.create_and_record(nil, m, nil, "in")
    sr.save 
    assert_equal("< This is a non SIP message", get_in_recording.get_recording[0][0..26])
    assert_equal("< This is a non SIP message", get_in_recording.get_info_only_recording[0])
  end
  
  def test_unknown_record_level
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:p_session_record).and_return("unknown")
    m.should_receive(:[]).with_any_args.and_return(true)
    m.should_receive(:class).and_return(Request)
    m.should_receive(:method).and_return("INVITE") 
    sr = SessionRecorder.create_and_record(nil, m, nil, "neutral")
    sr.save 
    str = "Unknown_record_level"
    assert_equal("! Unknown_record_level", get_neutral_recording.get_recording[0][0...str.size+2])
  end
  
  def test_unknown_direction
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:p_session_record).and_return("unknown")
    m.should_receive(:[]).with_any_args.and_return(true)
    m.should_receive(:class).and_return(Request)
    m.should_receive(:method).and_return("INVITE") 
    sr = SessionRecorder.create_and_record(nil, m, nil, "neutral")
    sr.record("unknown", m)
    sr.save 
    str = "UNKNOWN DIRECTION Unknown_record_level"
    assert_equal(str, get_neutral_recording.get_recording[1][0...str.size])
  end
  
  def test_recordable
    m = FlexMock.new
    m.should_receive(:call_id).and_return("my_call_id")
    m.should_receive(:p_session_record).and_return("msg-info")
    m.should_receive(:[]).with_any_args.and_return(true)
    m.should_receive(:class).and_return(Request)
    m.should_receive(:method).and_return("INVITE") 
    sr = SessionRecorder.create_and_record(nil, m, nil, "in")
    sr.save 
    assert_raise(RuntimeError) { sr.io = StringIO.new }
    assert_raise(RuntimeError) { sr.record("in", "Hello") }
    assert_raise(RuntimeError) { sr.save }
    assert_equal("< INVITE", get_in_recording.get_recording[0])
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = nil
    super
  end
  
end
