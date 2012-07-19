
require 'driven_sip_test_case'

class TestCancel < DrivenSipTestCase
   
  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "cancel")
    super
  end
  
  def test_cancel
    #set_controller("CancelCase::UacCancelController") 
    self.expected_flow = ["> INVITE {1,}", "! Exception_while_sending_CANCEL", "> INVITE {0,}", "< 100", "> CANCEL", "< 200"]
    start_named_controller("CancelCase::UacCancelController")
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE {1,}", "> 100", "< CANCEL", "> 200"]
    verify_call_flow(:in)
  end
  
end

