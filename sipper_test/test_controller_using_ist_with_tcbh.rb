require 'driven_sip_test_case'

class TestControllerUsingIstWithTcbh < DrivenSipTestCase

  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "ist_tcbh")
    super
  end
  
  
  def test_ist_controllers
    self.expected_flow = ["> INVITE {1,}", "< 100", "< 200", "> ACK"]
    start_named_controller("SipIst::UacIstTcbhController")
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE {1,}", "> 100", "> 200", "< ACK", "! Header_found"]
    verify_call_flow(:in)
    
    record_in = get_in_recording(0)
    assert_header_value_in_recording_equals(record_in.get_recording[2], :test_response_header, "Sipper")
  end
  
end


