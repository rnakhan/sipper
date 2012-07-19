require 'driven_sip_test_case'

class TestSmcController < DrivenSipTestCase
   
  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "state_machine_based")
    super
  end
  
  def test_smc
    #set_controller("CancelCase::UacCancelController") 
    self.expected_flow = ["> INVITE", "< 200", "> ACK", "> MESSAGE", "< 200", "> MESSAGE", "< BYE", "> 200"]
    start_named_controller("Smc::UacMessageController")
    verify_call_flow(:out)
  end
  
end
