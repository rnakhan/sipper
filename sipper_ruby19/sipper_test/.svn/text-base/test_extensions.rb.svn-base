
$:.unshift File.join(File.dirname(__FILE__),"..","sipper")

require 'driven_sip_test_case'

class TestExtensions < DrivenSipTestCase
   
  def setup
    @orig_cp = SipperConfigurator[:ControllerPath]
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "extensions")
    super
  end
  
  def test_extensions
    start_named_controller("ExtensionUacController")
    
    record_in = get_in_recording(0)
    
    assert_header_value_in_recording_equals(record_in.get_recording[0], :from, "TEST EXTENSION <sip:nasir@sipper.com>;tag=1")
    
  end
  
  def teardown
    SipperConfigurator[:ControllerPath] = @orig_cp
    super
  end
  
end
