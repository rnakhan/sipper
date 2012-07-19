$:.unshift File.join(File.dirname(__FILE__),"..","sipper")
require 'driven_sip_test_case'

class TestThTest < DrivenSipTestCase 

  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "ctrl_trhandler")
    SipperConfigurator[:SessionRecord]='msg-info'
    super
  end

  def test_case_1
    self.expected_flow = ["> INFO","< 200"]
    start_named_controller("UacTrHandlerController")
    verify_call_flow(:out)
    self.expected_flow = ["< MESSAGE","> 200"]
    verify_call_flow(:in)
  end
end
