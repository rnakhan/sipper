require 'base_test_case'

class TestDynamicParse < BaseTestCase
  
  def test_dynamic_supported
        str = %q{SIP/2.0 200 OK
Contact: <sip:127.0.0.1:5060;transport=UDP>
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2
Allow: INVITE, BYE, ACK, OPTIONS
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
Cseq: 1 INVITE}

    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2", r.via.to_s)
    
    # Via
    pv = r.via  
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2", pv.to_s)
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061", pv.header_value)
    assert_equal({"branch"=>"z9hG4bK-2352-1-0","received"=>"127.0.0.2"}, pv.header_params)
    assert_equal("Via", pv.name)
    assert_equal("SIP", pv.protocol)
    assert_equal("2.0", pv.version)
    assert_equal("UDP", pv.transport)
    assert_equal("127.0.0.1", pv.sent_by_ip)
    assert_equal("6061", pv.sent_by_port)
    assert_equal("z9hG4bK-2352-1-0", pv.branch)
    assert_equal("127.0.0.2", pv.received)
    assert_equal(nil, pv.ttl)
    assert_equal(nil, pv.maddr)
    assert(!pv.default_parse?)
  
    
  end
  
    def test_dynamic_supported_mv
        str = %q{SIP/2.0 200 OK
Contact: <sip:127.0.0.1:5060;transport=UDP>
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2
Via: SIP/2.0/UDP 128.0.0.1:6062;branch=z9hG4bK-2353-1-0;received=127.0.0.3
Allow: INVITE, BYE, ACK, OPTIONS
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
Cseq: 1 INVITE}

    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2", r.via.to_s)
    
    # Via
    pv = r.via
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061", pv.header_value)
    assert_equal({"branch"=>"z9hG4bK-2352-1-0","received"=>"127.0.0.2"}, pv.header_params)
    assert_equal("Via", pv.name)
    assert_equal("SIP", pv.protocol)
    assert_equal("2.0", pv.version)
    assert_equal("UDP", pv.transport)
    assert_equal("127.0.0.1", pv.sent_by_ip)
    assert_equal("6061", pv.sent_by_port)
    assert_equal("z9hG4bK-2352-1-0", pv.branch)
    assert_equal("127.0.0.2", pv.received)
    assert_equal(nil, pv.ttl)
    assert_equal(nil, pv.maddr)
    assert(!pv.default_parse?)
    
    pv = r.vias[1]
    assert_equal("SIP/2.0/UDP 128.0.0.1:6062;branch=z9hG4bK-2352-1-0;received=127.0.0.2", pv.to_s)
    assert_equal("SIP/2.0/UDP 128.0.0.1:6062", pv.header_value)
    assert_equal({"branch"=>"z9hG4bK-2353-1-0","received"=>"127.0.0.3"}, pv.header_params)
    assert_equal("Via", pv.name)
    assert_equal("SIP", pv.protocol)
    assert_equal("2.0", pv.version)
    assert_equal("UDP", pv.transport)
    assert_equal("128.0.0.1", pv.sent_by_ip)
    assert_equal("6062", pv.sent_by_port)
    assert_equal("z9hG4bK-2353-1-0", pv.branch)
    assert_equal("127.0.0.3", pv.received)
    assert_equal(nil, pv.ttl)
    assert_equal(nil, pv.maddr)
    assert(!pv.default_parse?)
    
  end
  
  
      def test_dynamic_supported_mv_same_line
        str = %q{SIP/2.0 200 OK
Contact: <sip:127.0.0.1:5060;transport=UDP>
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2, SIP/2.0/UDP 128.0.0.1:6062;branch=z9hG4bK-2353-1-0;received=127.0.0.3
Allow: INVITE, BYE, ACK, OPTIONS
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
Cseq: 1 INVITE}

    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    
    # Via
    pv = r.via
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2", pv.to_s)
    assert_equal("SIP/2.0/UDP 127.0.0.1:6061", pv.header_value)
    assert_equal({"branch"=>"z9hG4bK-2352-1-0","received"=>"127.0.0.2"}, pv.header_params)
    assert_equal("Via", pv.name)
    assert_equal("SIP", pv.protocol)
    assert_equal("2.0", pv.version)
    assert_equal("UDP", pv.transport)
    assert_equal("127.0.0.1", pv.sent_by_ip)
    assert_equal("6061", pv.sent_by_port)
    assert_equal("z9hG4bK-2352-1-0", pv.branch)
    assert_equal("127.0.0.2", pv.received)
    assert_equal(nil, pv.ttl)
    assert_equal(nil, pv.maddr)
    assert(!pv.default_parse?)
    
    pv = r.vias[1]
    assert_equal("SIP/2.0/UDP 128.0.0.1:6062;branch=z9hG4bK-2352-1-0;received=127.0.0.2", pv.to_s)
    assert_equal("SIP/2.0/UDP 128.0.0.1:6062", pv.header_value)
    assert_equal({"branch"=>"z9hG4bK-2353-1-0","received"=>"127.0.0.3"}, pv.header_params)
    assert_equal("Via", pv.name)
    assert_equal("SIP", pv.protocol)
    assert_equal("2.0", pv.version)
    assert_equal("UDP", pv.transport)
    assert_equal("128.0.0.1", pv.sent_by_ip)
    assert_equal("6062", pv.sent_by_port)
    assert_equal("z9hG4bK-2353-1-0", pv.branch)
    assert_equal("127.0.0.3", pv.received)
    assert_equal(nil, pv.ttl)
    assert_equal(nil, pv.maddr)
    assert(!pv.default_parse?)
    
  end
  
  # Tests multivalued same line unsupported header
  def test_dynamic_unsupported
    str = %q{SIP/2.0 200 OK
Contact: <sip:127.0.0.1:5060;transport=UDP>
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
P-Test-Header: test;param1=v1;param2=v2, test2;param1=v21;param2=v22
Cseq: 1 INVITE}
    
    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    ppth = r.p_test_header
    assert_equal("test", ppth.header_value)
    assert_equal({"param1"=>"v1", "param2"=>"v2"}, ppth.header_params)
    assert_equal("test;param1=v1;param2=v2", ppth.to_s)
    assert(ppth.default_parse?)
    
    ppth = r.p_test_headers[1]
    assert_equal("test2", ppth.header_value)
    assert_equal({"param1"=>"v21", "param2"=>"v22"}, ppth.header_params)
    assert_equal("test2;param1=v21;param2=v22", ppth.to_s)
    assert(ppth.default_parse?)
    
  end
  
  def test_dynamic_not_incoming
    r = Request.create_initial("invite", "sip:nina@codepresso.com", :from=>"sip:nina@codepresso.com")
    pf = r.from
    assert_equal("<sip:nina@codepresso.com>", pf.to_s)
  end
  
  def test_dynamic_non_header
    #assert_raise(TypeError){ "non_header".parse }
  end
  
  def test_auth_header
        str = %q{SIP/2.0 401 Not authenticated
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
WWW-Authenticate: Digest realm="atlanta.com", domain="sip:ss1.carrier.com", nonce="f84f1cec41e6cbe5aea9c8e88d359", stale=FALSE, algorithm=MD5
Cseq: 1 INVITE}

    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal('Digest realm="atlanta.com", domain="sip:ss1.carrier.com", nonce="f84f1cec41e6cbe5aea9c8e88d359", stale=FALSE, algorithm=MD5', r.www_authenticate.to_s)
    
    # WWW Authenticate
    pa = r.www_authenticate  
    assert_equal('"atlanta.com"', pa.realm)
    assert_equal('"sip:ss1.carrier.com"', pa.domain)
    assert_equal("FALSE", pa.stale)
    assert_equal("MD5", pa.algorithm)
    assert(!pa.default_parse?)
  end
  
  
   def test_authorization_header
        str = %q{INVITE sip:nasir@sipper.com SIP/2.0
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
Authorization: Digest username="bob", realm="biloxi.com", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", uri="sip:bob@biloxi.com", qop=auth, nc=00000001, cnonce="0a4f113b", response="6629fae49393a05397450978507c4ef1", opaque="5ccc069c403ebaf9f0171e9517f40e41"
Cseq: 1 INVITE}

    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal('Digest username="bob", realm="biloxi.com", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", uri="sip:bob@biloxi.com", qop=auth, nc=00000001, cnonce="0a4f113b", response="6629fae49393a05397450978507c4ef1", opaque="5ccc069c403ebaf9f0171e9517f40e41"', r.authorization.to_s)
    
    # Authorization
    pa = r.authorization  
    assert_equal('"biloxi.com"', pa.realm)
    assert_equal('"sip:bob@biloxi.com"', pa.uri)
    assert_equal('"dcd98b7102dd2f0e8b11d0f600bfb0c093"', pa.nonce)
    assert_equal('auth', pa.qop)
    assert_equal('00000001', pa.nc)
    assert_equal('"0a4f113b"', pa.cnonce)
    assert_equal('"6629fae49393a05397450978507c4ef1"', pa.response)
    assert_equal('"5ccc069c403ebaf9f0171e9517f40e41"', pa.opaque)
    assert(!pa.default_parse?)
  end
  
    def test_authinfo_header
        str = %q{SIP/2.0 200 OK
Call-Id: 1-2352@127.0.0.1
Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2
From: sipp <sip:sipp@127.0.0.1:6061>;tag=1
To: sut <sip:service@127.0.0.1:5060>;tag=1
Authentication-Info: nextnonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", qop=auth, nc=00000001, cnonce="0a4f113b", rspauth="6629fae49393a05397450978507c4ef1"
Cseq: 1 INVITE}

    msg = [str, ["AF_INET", 33303, "localhost.localdomain", "127.0.0.1"]]
    r = Message.parse msg
    assert_equal('nextnonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", qop=auth, nc=00000001, cnonce="0a4f113b", rspauth="6629fae49393a05397450978507c4ef1"', r.authentication_info.to_s)
    
    # Auth info
    pa = r.authentication_info  
    assert_equal("Authentication-Info", pa.name)
    assert_equal('"dcd98b7102dd2f0e8b11d0f600bfb0c093"', pa.nextnonce)
    assert_equal('auth', pa.qop)
    assert_equal('00000001', pa.nc)
    assert_equal('"0a4f113b"', pa.cnonce)
    assert_equal('"6629fae49393a05397450978507c4ef1"', pa.rspauth)
    assert(!pa.default_parse?)
  end
  
  
  
end
