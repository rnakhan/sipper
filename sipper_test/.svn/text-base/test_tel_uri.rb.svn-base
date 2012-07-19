require 'base_test_case'
require 'sip_headers/sipuri'

# <>
class TestTelUrl < BaseTestCase

  #tel:telephone-subscriber
  def test_simple1
    uri = URI::SipUri.new
    uri.assign("tel:+12015550123")
    assert_equal('tel', uri.proto)
    assert_equal('+12015550123', uri.host)
    assert_equal('tel:+12015550123', uri.to_s)
  end
  
  #tel:telephone-subscriber;uri-parameters
  def test_with_param
    uri = URI::SipUri.new
    uri.assign("tel:7460;ext=abc;phone-context=example.com")
    assert_equal('tel', uri.proto)
    assert_equal('7460', uri.host)
    assert_equal({'ext'=>'abc','phone-context'=>'example.com'}, uri.uri_params)
    assert_equal('tel:7460;ext=abc;phone-context=example.com', uri.to_s)
  end
end