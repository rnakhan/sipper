$:.unshift File.join(File.dirname(__FILE__),"..","sipper")


require 'stringio'
require 'driven_sip_test_case'

class TestEte < DrivenSipTestCase
   
  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "ete")
    super
  end
  
  def test_ete_flow
    start_named_controller("UacController")
    
    record_in = get_in_recording(0)
    record_out = get_out_recording(0)
    
    # uac
    assert_equal("> INVITE sip:nasir@agnity.com SIP/2.0", record_out.get_recording[0][0..36])
    assert_equal("< SIP/2.0 200 OK", record_out.get_recording[1][0..15])
    
    # need to check if the Contact was set right for the subsequent 
    # request from UAC as it received in the first 200 OK.
    # first check the contact in 200 OK from UAS
    assert_header_value_in_recording_equals(record_in.get_recording[1], :contact, "<sip:nasir@home.com>")
    
    # now check the same value in r-uri in subsequent request
    assert_uri_in_recording_equals(record_out.get_recording[4], "> INVITE sip:nasir@home.com SIP/2.0")
    
    
  end
  
end

# ruby_obj = File.open("my.yaml") {|yf| YAML::load(yf)}