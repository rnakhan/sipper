
require 'base_test_case'
require 'message'

class TestMultipartParser < BaseTestCase

 def test_multipart
    str = %q{INVITE sip:service@127.0.0.1:5060 SIP/2.0
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>
Call-ID: 1-2352@127.0.0.1
CSeq: 1 INVITE
Contact: sip:sippp@127.0.0.1:6061
Max-Forwards: 70
Subject: Performance Test
Content-Type: multipart/mixed;boundary=xxx-unique-boundary-xxx
Content-Length:  391

--xxx-unique-boundary-xxx
Content-Type: text/plain

hello
--xxx-unique-boundary-xxx
Content-Type: application/sdp

v=0
o=nkhan 1250002394 1250002394 IN IP4 127.0.0.1
s=Sipper Session
c=IN IP4 127.0.0.1
t=3458991194 0

--xxx-unique-boundary-xxx
Content-Type: application/sdp

v=0
o=nkhan 1250002394 1250002394 IN IP4 127.0.0.1
s=Sipper Session
c=IN IP4 127.0.0.1
t=3458991194 0

--xxx-unique-boundary-xxx--
}

sdp_only_str1 = %q{v=0
o=nkhan 1250002394 1250002394 IN IP4 127.0.0.1
s=Sipper Session
c=IN IP4 127.0.0.1
t=3458991194 0
}



    msg = [str, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    multipart_content = Multipart::MultipartParser.parse(r.contents,r.content_type) 
    
    assert_equal("xxx-unique-boundary-xxx", multipart_content.boundary)
    assert_equal("mixed", multipart_content.subtype)
    
    assert_equal(3, multipart_content.get_count)
    assert_equal("text/plain", multipart_content.get_bodypart(0).type)
    assert_equal("application/sdp", multipart_content.get_bodypart(1).type)
    assert_equal("application/sdp", multipart_content.get_bodypart(2).type)
    
    assert_equal("hello", multipart_content.get_bodypart(0).contents.to_s)
    assert_equal(sdp_only_str1, multipart_content.get_bodypart(1).contents.join("\n"))
    assert_equal(sdp_only_str1, multipart_content.get_bodypart(2).contents.join("\n"))
    
  end    
  
end