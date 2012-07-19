
require 'driven_sip_test_case'
require 'test/unit'

class TestMultiple < DrivenSipTestCase
   
  def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "multiple")
    super
  end
  
  def test_message
    start_named_controller("SipMessage::UacMsgController")
    sleep 1  #todo fix the sleeping, make it automatic
    
    record_in = get_in_recording
    record_out = get_out_recording
    
    # uac
    assert_equal("> MESSAGE", record_out.get_recording[0])
    assert_equal("< 200", record_out.get_recording[1])
   
        
    # uas
    assert_equal("< MESSAGE", record_in.get_recording[0])
    assert_equal("> 200", record_in.get_recording[1])
  end
  
  
  
  def test_info
    start_named_controller("InfoTest::UacInfoController")
    sleep 1  #todo fix the sleeping, make it automatic
    
    record_in = get_in_recording
    record_out = get_out_recording
    
    # uac
    assert_equal("> INFO", record_out.get_recording[0])
    assert_equal("< 200", record_out.get_recording[1])
   
        
    # uas
    assert_equal("< INFO", record_in.get_recording[0])
    assert_equal("> 200", record_in.get_recording[1])
  end
  
  
end
