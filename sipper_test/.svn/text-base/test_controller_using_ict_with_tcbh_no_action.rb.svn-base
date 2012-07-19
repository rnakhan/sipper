
require 'driven_sip_test_case'

class TestControllerUsingIctWithTcbhNoAction < DrivenSipTestCase

  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "ict_tcbh")
    super
  end
  
  
  def test_ict_controllers
    orig = SipperConfigurator[:ProtocolCompliance] 
    SipperConfigurator[:ProtocolCompliance] = 'lax'
    self.expected_flow = ["> INVITE", "< 400", "> ACK"]
    start_named_controller("SipIct::UacIctTcbhNoActionController")
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 400", "< ACK"]
    verify_call_flow(:in)

    SipperConfigurator[:ProtocolCompliance] = orig
  end
  
end
