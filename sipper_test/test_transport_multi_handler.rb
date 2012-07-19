
$:.unshift File.join(File.dirname(__FILE__),"..","sipper")
require 'driven_sip_test_case'

class TestTransportMultiHandler < DrivenSipTestCase 

  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "multi_trhandlers")
    SipperConfigurator[:SessionRecord]='msg-info'
    super
  end

  def test_case_1
    start_named_controller("UacMultiTrHandlerController")
    self.expected_flow = ["< INFO", "! Transform_OK", "> 200"]
    verify_call_flow(:in)
  end
end