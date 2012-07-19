
require 'base_test_case'
require 'sdp/sdp_parser'
require 'message'

class TestSdp < BaseTestCase

 def test_sdp
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

sdp_only_str1 = %q{v=0
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

sdp_only_str2 = %q{v=0
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
}

sdp_only_str3 = %q{v=0
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
a=recvonly
}

sdp_only_str4 = %q{v=0
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
b=AS:12600
a=recvonly
}

    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    sdp = SDP::SdpParser.parse(r.contents)
    assert_equal(sdp_only_str1, sdp.format_sdp("\n"))
    sdp.remove_media_line_at(1)
    assert_equal(sdp_only_str2, sdp.format_sdp("\n"))
    
    sdp.add_media_attribute_at(0, "recvonly")
    
    
    
    assert_equal(sdp_only_str3, sdp.format_sdp("\n"))
    assert_equal(["recvonly"], sdp.get_media_attributes_at(0))
    sdp.remove_media_attribute_at(0, "recvonly")
    assert_equal(sdp_only_str2, sdp.format_sdp("\n"))
    
    sdp.add_media_attribute_at(0, "recvonly")
    sdp.add_media_attribute_at(0, "AS:12600", :b)
    assert_equal(sdp_only_str4, sdp.format_sdp("\n"))
    assert_equal(["AS:12600"], sdp.get_media_attributes_at(0, :b))
    
  end    
  
end