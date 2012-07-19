require 'driven_sip_test_case'

class TestControllerUsingIctWithTcbh < DrivenSipTestCase

  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "ict_tcbh")
    super
  end
  
  
  def test_ict_controllers
    self.expected_flow = ["> INVITE", "< 200", "> INFO"]
    start_named_controller("SipIct::UacIctTcbhController")
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200", "< INFO"]
    verify_call_flow(:in)
    
    record_in = get_in_recording(0)
    assert_header_value_in_recording_equals(record_in.get_recording[0], :test_header, "Sipper")
  end
  
end


