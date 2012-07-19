require 'base_test_case'

class TestMessage < BaseTestCase

  def setup
    @orig_methods = Message.instance_methods
  end
  
  def test_init
    m = Message.new(:a=>"first", :b=>"second")
    assert_equal("first", m.a.to_s)
    assert_equal("second", m.b.to_s)
    assert_nil(m.rcvd_from_info)
  end
  
  def test_parse_request
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>
Call-ID: 1-2352@127.0.0.1
CSeq: 1 INVITE
Contact: sip:sippp@127.0.0.1:6061
Max-Forwards: 70
Subject: Performance Test
Content-Type: application/sdp
Content-Length:  129

v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000}

    body_str = %q{v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000
}

    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_instance_of(Request, r)
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2", r.via.to_s)
    assert_equal(129, r.content_len)  # no \r in text
    assert_equal(["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"], r.rcvd_from_info )
    assert_equal("v=0", r.contents[0])
    assert_equal("a=rtpmap:0 PCMU/8000", r.contents[6])
    assert(r.is_request?)
    assert_equal(body_str, r.body.gsub("\r", "")) # as no \r in text
  end
  
  
    def test_parse_request_with_rport
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP 127.0.0.1:6061;rport;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>
Call-ID: 1-2352@127.0.0.1
CSeq: 1 INVITE
Contact: sip:sippp@127.0.0.1:6061
Max-Forwards: 70
Subject: Performance Test
Content-Type: application/sdp
Content-Length:  129

v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000}

    body_str = %q{v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000
}

    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_instance_of(Request, r)
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;rport=33302;branch=z9hG4bK-2352-1-0;received=127.0.0.2", r.via.to_s)
    assert_equal(["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"], r.rcvd_from_info )
  end
  
  def test_parse_request_with_compact
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
v: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
f: sipp <sip:sipp@127.0.0.1:6061>;tag=1
t: sut <sip:service@127.0.0.1:5060>
i: 1-2352@127.0.0.1
CSeq: 1 INVITE
m: sip:nasir@127.0.0.1:6061
Max-Forwards: 70
s: Functional Test
c: application/sdp
l: 129

v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000}

    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_instance_of(Request, r)
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2", r.via.to_s)
    assert_equal("sipp <sip:sipp@127.0.0.1:6061>;tag=1", r.from.to_s)
    assert_equal("sut <sip:service@127.0.0.1:5060>", r.to.to_s)
    assert_equal("1-2352@127.0.0.1", r.call_id.to_s)
    assert_equal("<sip:nasir@127.0.0.1:6061>", r.contact.to_s)
    assert_equal("Functional Test", r.subject.to_s)
    assert_equal("application/sdp", r.content_type.to_s)
    assert_equal("129", r.content_length.to_s)
    assert(r.is_request?)
  end
  
    def test_partial_content
      orig = SipperConfigurator[:ProtocolCompliance]
      SipperConfigurator[:ProtocolCompliance] = 'strict'
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>
Call-ID: 1-2352@127.0.0.1
CSeq: 1 INVITE
Contact: sip:sippp@127.0.0.1:6061
Max-Forwards: 70
Subject: Performance Test
Content-Type: application/sdp
Content-Length: 10

v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000}

    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_instance_of(Request, r)
    assert_equal("v=0", r.contents[0])
    assert_equal("o=user1", r.contents[1])
    SipperConfigurator[:ProtocolCompliance] = orig
  end
  
  
  # Content-Length header is 1000
  def test_truncated_content
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>
Call-ID: 1-2352@127.0.0.1
CSeq: 1 INVITE
Contact: sip:sippp@127.0.0.1:6061
Max-Forwards: 70
Subject: Performance Test
Content-Type: application/sdp
Content-Length: 1000

v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000}

    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal(129, r.content_len)  # assuming a \r in content_len we add
    assert_equal(1000, r.content_length.to_s.to_i)
  end
  
  
  def test_via_received
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP ash@home.com;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>
Call-ID: 1-2352@127.0.0.1
CSeq: 1 INVITE
Contact: sip:sippp@127.0.0.1:6061
Max-Forwards: 70
Subject: Performance Test
Content-Type: application/sdp
Content-Length:  129

v=0
o=user1 53655765 2353687637 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 6000 RTP/AVP 0
a=rtpmap:0 PCMU/8000} 
    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal("SIP/2.0/UDP ash@home.com;branch=z9hG4bK-2352-1-0;received=127.0.0.2", r.via.to_s)
  end
  
  def test_parse_response
    str = %q{SIP/2.0 200 OK
Contact: <sip:127.0.0.1:5060;transport=UDP>
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
Cseq: 1 INVITE}
    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_instance_of(Response, r)
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0", r.via.to_s)
    assert_equal(["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"], r.rcvd_from_info )
    assert(r.is_response?)
  end
  
  def test_parse_junk
    str = "junk"
    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    assert_raise(ArgumentError) {r = Message.parse msg}
  end
  
  def test_each
    _make_message
    assert(@m.respond_to?(:each))
    n = 0
    @m.each {|k,v|  n+=1}
    assert_equal(8, n) # 3 addnl system headers
  end
  
  def test_copy_from
    _make_message
    m = Message.new
    m.copy_from(@m, :via, :from)
    assert_equal(@m.via, m.via)
    assert_equal(@m.from, m.from)
    assert_nil(m.to)
    assert_nothing_raised{m.copy_from(@m, :blah)}  #non existent header
    assert(!m.respond_to?(:blah))
  end
  
  def test_copy_from_2
    _make_message
    m = Message.new
    m.copy_from(@m, :_sipper_all)
    @m.each_header {|h| assert_equal(@m[h], m[h])}
  end
  
  
  def test_dynamic
    m = Message.new
    m.via = str = "SIP/2.0/UDP pc21@biloxi.com;branch=z9hG4bK-2352-1-0"
    assert_equal(str, m.via.to_s)
    assert_equal(str, m.vias[0].to_s)
    str2 = "SIP/2.0/UDP pc44@biloxi.com;branch=z9hG4bK-2353-1-0"
    m.add_via(str2)
    assert_equal(str, m.vias[0].to_s)
    assert_equal(str2, m.vias[1].to_s)
    assert_equal(str, m.via.to_s)
    str3 = m.pop_via.to_s
    assert_equal(str, str3)
    assert_equal(str2, m.via.to_s)
    m.push_via(str3)
    assert_equal(str, m.via.to_s)
    assert_equal(str2, m.vias[1].to_s)
    m.via = str4 = "SIP/2.0/UDP pc55@biloxi.com;branch=z9hG4bK-2353-1-0"
    assert_equal(str4, m.via.to_s)
    assert(1, m.vias.length)
    m.via = [str, str2]
    assert_equal(str, m.via.to_s)
    assert_equal(str, m.vias[0].to_s)
    assert_equal(str2, m.vias[1].to_s)
  end
  
  def test_popnilout
    m = Message.new
    m.via = "SIP/2.0/UDP pc21@biloxi.com;branch=z9hG4bK-2352-1-0"
    assert_not_nil(m.via)
    m.pop_via()
    assert_nil(m.via)
  end
  
  def test_blank_value
    m = Message.new
    m.via = ''
    assert_not_nil(m.via)
  end
  
  def test_multivalued
    msg = Message.new
    msg.route = "sip:r@oute1, sip:r@oute2, sip:r@oute3"
    _check_mv_route( msg )
    
    msg = Message.new
    msg.route = ["sip:r@oute1", "sip:r@oute2", "sip:r@oute3"]
    _check_mv_route( msg )
    
    msg = Message.new
    msg.add_route("sip:r@oute1").add_route("sip:r@oute2").add_route("sip:r@oute3")
    _check_mv_route( msg )
    
    msg = Message.new
    msg.push_route("sip:r@oute3").push_route("sip:r@oute2").push_route("sip:r@oute1")
    _check_mv_route( msg )
  end
  
  
  def test_array_access
    _make_message
    assert_equal("sipp <sip:sipp@127.0.0.1:6061>;tag=1", @m[:from][0].to_s)
    assert(!@m.respond_to?(:blah))
    @m[:blah] = "blah"
    assert(@m.respond_to?(:blah))
    assert_equal(["blah"], @m[:blah].map{|x| x.to_s})
    assert_equal("blah", @m.blah.to_s)
    @m[:blahblah] = arr = ["blah", "blah"]
    assert_equal(arr, @m[:blahblah].map {|x| x.to_s})
    assert_equal("blah", @m.blahblah.to_s)
  end
  
  def test_content
    _make_message
    @m.content = "v=0\r\ns=-\r\nt=0 0" # translates to ["v=0", "s=-", "t=0 0"] with usual \r\n
    assert_equal(17, @m.content_len)
    assert_equal("v=0", @m.content)
    assert_equal(["v=0", "s=-", "t=0 0"], @m.contents)
  end
  
  def test_tags
    _make_message
    assert_equal("1", @m.from_tag)
    assert_equal("azxs21", @m.to_tag)
  end
  
  def test_header_order
    _make_message
    order = [:to, :from, :via, :call_id, :max_forwards, :non_existent1, :p_asserted_identity, :cseq, :non_existent2]
    @m.header_order = order
    msgstr = @m.to_s
    idx = 0
    order.each do |h|
      next_idx = msgstr.index(SipperUtil.headerize(h)+": ")
      if next_idx
        assert(next_idx > idx) 
        idx = next_idx  
      end
    end
  end
    
  def _make_message
    @m = Request.create_initial("invite", "sip:bob@biloxi.com", 
           :p_asserted_identity => "sip:bobber@home.com",
           :via => "SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0",
           :from => "sipp <sip:sipp@127.0.0.1:6061>;tag=1",
           :to => "sut <sip:service@127.0.0.1:5060>;tag=azxs21",
           :cseq => "1 INVITE")                        
  end
  
  def _check_mv_route(m)
    assert_equal("<sip:r@oute1>", m.route.to_s)
    assert_equal(["<sip:r@oute1>", "<sip:r@oute2>", "<sip:r@oute3>"], m.routes.map{|x| x.to_s})
    assert_equal(["<sip:r@oute1>", "<sip:r@oute2>", "<sip:r@oute3>"], m[:route].map{|x| x.to_s})
  end
  
  def teardown
    new_methods = Message.instance_methods - @orig_methods
    new_methods.each do |m|
      Message.class_eval do
        undef_method m.to_sym   
      end
    end
    @m = nil
  end
  
  private :_make_message, :_check_mv_route
end
