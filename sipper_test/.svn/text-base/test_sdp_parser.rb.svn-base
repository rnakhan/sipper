require 'base_test_case'
require 'sdp/sdp_parser'
require 'message'

class TestSdpParser < BaseTestCase

  def test_simple_parse
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
a=rtpmap:0 PCMU/8000
b=AS:12600}
    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    sdp = SDP::SdpParser.parse(r.contents)
    assert(SDP::Sdp, sdp.class)
    assert_equal("0", sdp.session_lines[:v])
    assert_equal("user1 53655765 2353687637 IN IP4 127.0.0.1", sdp.session_lines[:o])
    assert_equal("-", sdp.session_lines[:s])
    assert_equal("IN IP4 127.0.0.1", sdp.session_lines[:c])
    assert_equal("0 0", sdp.session_lines[:t])
    assert_equal(5, sdp.session_lines.length)
    assert_equal(1, sdp.media_lines.length)
    assert_equal(3, sdp.media_lines[0].length)
    ma = sdp.media_lines.shift
    assert_equal("audio 6000 RTP/AVP 0", ma[:m])
    assert_equal("rtpmap:0 PCMU/8000", ma[:a])
    assert_equal("AS:12600", ma[:b])
  end
  
  
    def test_response_parse
    str = %q{SIP/2.0 180 Ringing
To: <sip:16504801001@10.17.131.250>;tag=ccb728-0-13d8-5a45cb-34600e79-5a45cb
From: 16504806767 <sip:16504806767@10.17.131.250:5072>;tag=3
Call-ID: 1-5192@10.17.205.135
Cseq: 1 INVITE
Contact: <sip:service@10.17.131.250:5080>
Content-Length: 216
Via: SIP/2.0/UDP 10.17.205.135:5066;branch=z9hG4bK-1-0-1
Content-Type: application/sdp


v=0
o=1234 53655765 2353687637 IN IP4 10.17.131.251
s=SnowShore Sdp
c=IN IP4 10.171.131.251
t=0 0
m=audio 6000 RTP/AVP 0 101
a=sendrecv
a=ptime:20
a=rtpmap:0 PCMU/8000
a=rtpmap:101 telephone-event/8000/1}
    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    sdp = SDP::SdpParser.parse(r.contents)
    assert(SDP::Sdp, sdp.class)
    assert_equal("0", sdp.session_lines[:v])
    assert_equal("1234 53655765 2353687637 IN IP4 10.17.131.251", sdp.session_lines[:o])
    assert_equal("SnowShore Sdp", sdp.session_lines[:s])
    assert_equal("IN IP4 10.171.131.251", sdp.session_lines[:c])
    assert_equal("0 0", sdp.session_lines[:t])
    
    assert_equal(1, sdp.media_lines.length)
    
    assert_equal(2, sdp.media_lines[0].length)
    ma = sdp.media_lines.shift
    assert_equal("audio 6000 RTP/AVP 0 101", ma[:m])
  end
  
  
  
  def test_multi_m_parse
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
Content-Length:  347  
  
v=0
o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
s=SDP Seminar
i=A Seminar on the session description protocol
u=http://www.example.com/seminars/sdp.pdf
e=j.doe@example.com (Jane Doe)
c=IN IP4 224.2.17.12/127
t=2873397496 2873404696
a=recvonly
a=some_attr
m=audio 49170 RTP/AVP 0
m=video 51372 RTP/AVP 99
a=rtpmap:99 h263-1998/90000
}

sdp_only_str = %q{v=0
o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
s=SDP Seminar
i=A Seminar on the session description protocol
u=http://www.example.com/seminars/sdp.pdf
e=j.doe@example.com (Jane Doe)
c=IN IP4 224.2.17.12/127
t=2873397496 2873404696
a=recvonly
a=some_attr
m=audio 49170 RTP/AVP 0
m=video 51372 RTP/AVP 99
a=rtpmap:99 h263-1998/90000
}

     msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
     r = Message.parse msg
     sdp = SDP::SdpParser.parse(r.contents)
     # sdp_only_str does not have \r
     assert_equal(sdp_only_str, sdp.format_sdp("\n"))
     assert_equal(9, sdp.session_lines.length)
     assert_equal(2, sdp.media_lines.length)
     assert_equal(1, sdp.media_lines[0].length)
     assert_equal(2, sdp.media_lines[1].length)
     ma = sdp.media_lines.shift
     assert_equal("audio 49170 RTP/AVP 0", ma[:m])
     ma = sdp.media_lines.shift
     assert_equal("video 51372 RTP/AVP 99", ma[:m])
     assert_equal("rtpmap:99 h263-1998/90000", ma[:a])
     
  end
end