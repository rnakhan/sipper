require 'base_test_case'
require 'sip_headers/sipuri'

# <sip:C.example;method=REFER?Refer-To="<sip:D.example>">
class TestSipUri < BaseTestCase

  #sip:host;uri-parameters?headers
  # sip:host
  def test_simple1
    uri = URI::SipUri.new
    uri.assign("sip:sipper.com")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('sip:sipper.com', uri.to_s)
  end
  
  # sip:host;uri-parameters
  def test_simple2
    uri = URI::SipUri.new
    uri.assign("sips:192.168.1.1;lr;transport=udp")
    assert_equal('sips', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal({'lr'=>'', 'transport'=>'udp'}, uri.uri_params)
    #assert_equal("sips:192.168.1.1;lr;transport=udp", uri.to_s)
  end
  
  # sip:host?headers
  def test_simple3
    uri = URI::SipUri.new
    uri.assign("sip:192.168.1.1?Refer-To=\"<sip:D.example>\"")
    assert_equal('sip', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal('<sip:D.example>', uri.headers['refer_to'].to_s)
    assert_nil(uri.headers['refer_to'].display_name)
    assert_equal("sip:D.example", uri.headers['refer_to'].uri )
    #assert_equal("sip:192.168.1.1?Refer-To=\"<sip:D.example>\"", uri.to_s)
  end
  
  
  def test_with_user
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@sipper.com")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('nkhan', uri.user)
  end
  
  def test_with_user_with_param
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1;lr;transport=udp")
    assert_equal('sip', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal({'lr'=>'', 'transport'=>'udp'}, uri.uri_params)
  end
  
  
  def test_with_user_with_port_and_param
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070;lr;method=INVITE")
    assert_equal('sip', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('5070', uri.port)
    assert_equal({'lr'=>'', 'method'=>'INVITE'}, uri.uri_params)
  end
  
  def test_with_user_with_port
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070")
    assert_equal('sip', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('5070', uri.port)
  end
  
  def test_with_user_and_passwd
    uri = URI::SipUri.new
    uri.assign("sip:nkhan:hello@sipper.com")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('hello', uri.password)
  end
  
  def test_with_user_and_passwd_with_param
    uri = URI::SipUri.new
    uri.assign("sip:nkhan:hello@sipper.com;lr;transport=udp")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('hello', uri.password)
    assert_equal({'lr'=>'', 'transport'=>'udp'}, uri.uri_params)
  end
  
  def test_with_user_and_passwd_and_port
    uri = URI::SipUri.new
    uri.assign("sip:nkhan:hello@sipper.com:5070;lr;transport=udp")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('hello', uri.password)
    assert_equal('5070', uri.port)
    assert_equal({'lr'=>'', 'transport'=>'udp'}, uri.uri_params)
  end
  
  def test_with_user_passwd_port_and_headers
    uri = URI::SipUri.new
    uri.assign("sip:nkhan:hello@sipper.com:5070;lr;transport=udp?Call-ID=\"mycallid\"&Test-Header=\"blah\"&No-Quote=plain")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('hello', uri.password)
    assert_equal('5070', uri.port)
    assert_equal({'lr'=>'', 'transport'=>'udp'}, uri.uri_params)
    assert_equal("mycallid", uri.headers['call_id'].to_s)
    assert_equal("blah", uri.headers['test_header'].to_s)
    assert_equal("plain", uri.headers['no_quote'].to_s)
    #assert_equal("sip:nkhan:hello@sipper.com:5070;lr;transport=udp?Call-ID=\"mycallid\"&Test-Header=\"blah\"", uri.to_s)
  end
  
  
  # sip:host:port;uri-parameters
  def test_with_host_port_and_params
    uri = URI::SipUri.new
    uri.assign("sip:sipper.com:5070;lr;transport=udp")
    assert_equal('sip', uri.proto)
    assert_equal('sipper.com', uri.host)
    assert_equal('5070', uri.port)
    assert_equal({'lr'=>'', 'transport'=>'udp'}, uri.uri_params)
  end
  
  
  def test_assign_no_parse
    uri = URI::SipUri.new
    uri.assign("sip:nkhan:hello@sipper.com::::::5070", false)
    assert_equal("sip:nkhan:hello@sipper.com::::::5070", uri.to_s)
  end
  
  def test_assign_no_parse_freeze
    uri = URI::SipUri.new
    uri.assign("sip:nkhan:hello@sipper.com::::::5070", false)
    uri.freeze
    assert_equal("sip:nkhan:hello@sipper.com::::::5070", uri.to_s)
    assert_raise(RuntimeError) { uri.proto = "sips"}
  end
  
  def test_with_user_with_port_freeze
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070")
    assert_equal('sip', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('5070', uri.port)
    uri.host = "sipper.com"
    uri.port = "5060"
    assert_equal("sip:nkhan@sipper.com:5060", uri.to_s)
    uri.freeze
    assert_raise(RuntimeError) { uri.proto = "sips"}
    assert_equal("sip:nkhan@sipper.com:5060", uri.to_s)
  end
  
  def test_mutators
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070;method=INVITE?Refer-To=%3Csip%3Ankhan%40sipper.com%3E")
    assert_equal('sip', uri.proto)
    assert_equal('192.168.1.1', uri.host)
    assert_equal('nkhan', uri.user)
    assert_equal('5070', uri.port)
    assert_equal({'method'=>'INVITE'}, uri.uri_params)
    assert_equal("<sip:nkhan@sipper.com>", uri.headers['refer_to'].to_s)
    assert_equal("sip:nkhan@192.168.1.1:5070;method=INVITE?Refer-To=%3Csip%3Ankhan%40sipper.com%3E", uri.to_s)
    uri.proto = "sips"
    uri.user = "nasir"
    uri.port = "5065"
    uri.host = "agnity.com"
    uri.uri_params['transport'] = "udp"
    uri.uri_params['method'] = nil
    assert_equal("sips:nasir@agnity.com:5065;transport=udp?Refer-To=%3Csip%3Ankhan%40sipper.com%3E", uri.to_s)
    uri.headers = {}
    assert_equal("sips:nasir@agnity.com:5065;transport=udp", uri.to_s)
  end
  
  def test_param_methods1
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070;method=INVITE")
    assert_equal("INVITE", uri.get_param(:method))
    uri.add_param(:transport, "udp")
    assert_equal("INVITE", uri.get_param(:method))
    assert_equal("udp", uri.get_param(:transport))
    assert(uri.has_param?(:transport))
    uri.remove_param(:method)
    assert(!uri.has_param?(:method))
    assert_equal("sip:nkhan@192.168.1.1:5070;transport=udp", uri.to_s)
  end
  
  def test_param_methods2
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070")
    assert_nil(uri.get_param(:method))
    uri.add_param(:transport, "udp")
    assert_equal("udp", uri.get_param(:transport))
    assert(uri.has_param?(:transport))
    assert_equal("sip:nkhan@192.168.1.1:5070;transport=udp", uri.to_s)
  end
  
  def test_header_methods1
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070?Refer-To=\"<sip:nkhan@sipper.com>\"")
    assert_equal(SipHeaders::ReferTo, uri.get_header(:refer_to).class)
    assert_equal("<sip:nkhan@sipper.com>", uri.get_header(:refer_to).to_s)
    uri.add_header("Call-Id", "123@1234:4555")
    assert_equal("<sip:nkhan@sipper.com>", uri.get_header(:refer_to).to_s)
    assert_equal("123@1234:4555", uri.get_header(:call_id).to_s)
    assert_equal(SipHeaders::Header, uri.get_header(:call_id).class)
    assert(uri.has_header?(:call_id))
    uri.remove_header(:refer_to)
    assert(!uri.has_header?(:refer_to))
    assert_equal("sip:nkhan@192.168.1.1:5070?Call-ID=123%401234%3A4555", uri.to_s)
  end
  
   def test_header_methods2
    uri = URI::SipUri.new
    uri.assign("sip:nkhan@192.168.1.1:5070")
    assert_nil(uri.get_header(:refer_to))
    uri.add_header("Call-Id", "123@1234:4555")
    assert_equal("123@1234:4555", uri.get_header(:call_id).to_s)
    assert_equal(SipHeaders::Header, uri.get_header(:call_id).class)
    assert(uri.has_header?(:call_id))
    uri.remove_header(:refer_to)
    assert(!uri.has_header?(:refer_to))
    assert_equal("sip:nkhan@192.168.1.1:5070?Call-ID=123%401234%3A4555", uri.to_s)
  end
end