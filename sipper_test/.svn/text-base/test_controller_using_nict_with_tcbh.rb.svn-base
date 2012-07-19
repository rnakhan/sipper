require 'driven_sip_test_case'

class TestControllerUsingNictWithTcbh < DrivenSipTestCase

  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "nict_tcbh")
    super
  end
  
  
  def test_nict_controllers
    self.expected_flow = ["> INFO", "< 200", "> MESSAGE"]
    start_named_controller("SipNict::UacNictTcbhController")
    verify_call_flow(:out)
    self.expected_flow = ["< INFO", "> 200", "< MESSAGE"]
    verify_call_flow(:in)
    
    record_in = get_in_recording(0)
    assert_header_value_in_recording_equals(record_in.get_recording[0], :test_header, "Sipper")
  end
  
end


