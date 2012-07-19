require 'base_test_case'
require 'ruby_ext/string'
require 'sip_headers/header'
require 'util/sipper_util'

class TestHeaderParse < BaseTestCase
  
  def setup
    @method = "invite"
    @uri = "sip:nasir@sipper.com"
    @code = 200
    @status = "OK"
    @rq = Request.create_initial(@method, @uri, :p_asserted_identity => "sip:nina@home.com")                        
    @rs = Response.create(@code, @status, :from=>"sip:nasir@codepresso.com")
  end
  
  def test_header_object
    assert(@rq.p_asserted_identity.class <= SipHeaders::Header)
    assert(@rq.from.class <= SipHeaders::From)
  end
  
  def test_header_string
    assert_equal("<sip:nina@home.com>", @rq.p_asserted_identity.to_s)
    assert_equal("<sip:nasir@codepresso.com>", @rs.from.to_s)
  end
  
  def test_parse_via
    via = "SIP/2.0/TLS 175.19.37.207:6062;branch=z9hG4bK-1-0"
    pv = SipHeaders::Via.new.assign(via)
    pv.name = SipperUtil.headerize("via") 
    assert_equal("Via", pv.name)
    assert_equal("SIP/2.0/TLS 175.19.37.207:6062;branch=z9hG4bK-1-0", pv.to_s)
    assert_equal("SIP/2.0/TLS 175.19.37.207:6062", pv.header_value)
    assert_equal({"branch"=>"z9hG4bK-1-0"}, pv.header_params)
    assert_equal("z9hG4bK-1-0", pv.branch)
    assert_equal("SIP", pv.protocol)
    assert_equal("2.0", pv.version)
    assert_equal("TLS", pv.transport)
    assert_equal("175.19.37.207", pv.sent_by_ip)
    assert_equal("6062", pv.sent_by_port)
    pv.sent_by_port = "6063"
    assert_equal("SIP/2.0/TLS 175.19.37.207:6063;branch=z9hG4bK-1-0", pv.to_s)
  end
  
  
  def test_parse_to
    to = "sip:msml@10.32.4.30:5066;tag=hssUA_4052825476-151"
    t = SipHeaders::To.new.assign(to)
    assert_equal("To", t.name)
    assert_equal("sip:msml@10.32.4.30:5066", t.uri.to_s)
  end
  # Via: SIP/2.0/UDP 10.17.205.49:5062
  
#  def test_parse_via_2543
#    via = "SIP/2.0/UDP 10.17.205.49:5062"
#    pv = SipHeaders::Via.new.assign(via)
#    pv.name = SipperUtil.headerize("via") 
#    assert_equal("Via", pv.name)
#    assert_equal("SIP", pv.protocol)
#    assert_equal("2.0", pv.version)
#    assert_equal("UDP", pv.transport)
#    assert_equal("SIP/2.0/UDP 10.17.205.49:5062", pv.to_s)
#    assert_equal("SIP/2.0/UDP 10.17.205.49:5062", pv.header_value)
#    assert_equal("10.17.205.49", pv.sent_by_ip)
#    assert_equal("5062", pv.sent_by_port)
#    pv.sent_by_port = "6063"
#    assert_equal("SIP/2.0/UDP 10.17.205.49:6063", pv.to_s)
#  end
  
  def test_parse_authenticate
    auth = 'Digest realm="atlanta.com", domain="sip:ss1.carrier.com", qop="auth", nonce="f84f1cec41e6cbe5aea9c8e88d359", opaque="", stale=FALSE, algorithm=MD5'
    pa = SipHeaders::WwwAuthenticate.new.assign(auth)
    pa.name = SipperUtil.headerize("WWW_Authenticate")
    assert_equal("WWW-Authenticate", pa.name)
    assert_equal('"atlanta.com"', pa.realm)
    assert_equal('"sip:ss1.carrier.com"', pa.domain)
    assert_equal('"auth"', pa.qop)
    assert_equal('""', pa.opaque)
    assert_equal("FALSE", pa.stale)
    assert_equal("MD5", pa.algorithm)
  end
  
  def test_parse_authorization
    auth = 'Digest username="bob", realm="biloxi.com", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", uri="sip:bob@biloxi.com", qop=auth, nc=00000001, cnonce="0a4f113b", response="6629fae49393a05397450978507c4ef1", opaque="5ccc069c403ebaf9f0171e9517f40e41"'
    pa = SipHeaders::Authorization.new.assign(auth)
    pa.name = SipperUtil.headerize("Authorization")
    assert_equal("Authorization", pa.name)
    assert_equal('"biloxi.com"', pa.realm)
    assert_equal('"sip:bob@biloxi.com"', pa.uri)
    assert_equal('"dcd98b7102dd2f0e8b11d0f600bfb0c093"', pa.nonce)
    assert_equal('auth', pa.qop)
    assert_equal('00000001', pa.nc)
    assert_equal('"0a4f113b"', pa.cnonce)
    assert_equal('"6629fae49393a05397450978507c4ef1"', pa.response)
    assert_equal('"5ccc069c403ebaf9f0171e9517f40e41"', pa.opaque)
  end
  
    def test_parse_authinfo
    auth = 'nextnonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", qop=auth, nc=00000001, cnonce="0a4f113b", rspauth="6629fae49393a05397450978507c4ef1"'
    pa = SipHeaders::AuthenticationInfo.new.assign(auth)
    pa.name = SipperUtil.headerize("Authentication_Info")
    assert_equal("Authentication-Info", pa.name)
    assert_equal('"dcd98b7102dd2f0e8b11d0f600bfb0c093"', pa.nextnonce)
    assert_equal('auth', pa.qop)
    assert_equal('00000001', pa.nc)
    assert_equal('"0a4f113b"', pa.cnonce)
    assert_equal('"6629fae49393a05397450978507c4ef1"', pa.rspauth)
  end
  
  
  def test_header_parameter
    assert_nil(@rq.to.tag)
    @rq.to.tag = "xyz"
    assert_equal("xyz", @rq.to.tag)
    @rq.my_header = "test_header"
    @rq.my_header.my_parameter = "test_parameter"
    assert_equal("test_parameter", @rq.my_header.my_parameter)
    assert_equal("test_header;my_parameter=test_parameter", @rq.my_header.to_s)
  end
  
  def test_frozen_header
    orig_via = @rq.via.to_s
    @rq.via.freeze
    assert_raise(TypeError){@rq.via.assign("SIP/2.0/TLS 175.19.37.207:6062;branch=z9hG4bK-1-0")}
    assert_equal(orig_via, @rq.via.to_s)
    assert_nothing_raised {@rq.via.new_tag="1"}
    assert_equal(orig_via, @rq.via.to_s)
  end
  
  def test_unparse_option
    @rq.from.assign("Nasir Khan <sip:nasir@sipper.com>;tag=1", false)
    assert_equal("Nasir Khan <sip:nasir@sipper.com>;tag=1", @rq.from.to_s)
    assert_nil(@rq.from.display_name)
    assert_nil(@rq.from.uri)
    @rq.from.tag = "2"
    assert_equal("Nasir Khan <sip:nasir@sipper.com>;tag=1", @rq.from.to_s)
    @rq.from.assign("Nasir Khan <sip:nasir@goblet.com>;tag=3", true)
    assert_equal("Nasir Khan <sip:nasir@goblet.com>;tag=3", @rq.from.to_s)
  end
  
  def test_unparse_new
    @rq.assign_unparsed(:foo, "bar")
    assert_equal("bar", @rq.foo.to_s)
    @rq.foo.x = "1"
    assert_equal("bar", @rq.foo.to_s)
  end
  
  def test_parse_reason
    reason_hdr = "SIP;cause=200;text=\"Call completed elsewhere\""
    pa = SipHeaders::Reason.new.assign(reason_hdr)
    pa.name = SipperUtil.headerize("Reason")
    assert_equal("Reason", pa.name)
    assert_equal("SIP", pa.protocol)
    assert_equal("200", pa.cause)
    assert_equal('"Call completed elsewhere"', pa.text)
  end
  
end
