
$:.unshift File.join(File.dirname(__FILE__),"..","sipper")

require 'driven_sip_test_case'

class TestStray < DrivenSipTestCase
   
  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "stray_message")
    super
  end
  
  def test_stray
    self.expected_flow = ["> INVITE", "< 100","< 200", "> ACK"]
    start_named_controller("StrayUacController")    
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100","> 200"] 
    verify_call_flow(:in)
    
  end
  
  def teardown
    SIP::StrayMessageManager.clear_handler
    super
  end
  
end

