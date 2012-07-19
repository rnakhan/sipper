$:.unshift File.join(File.dirname(__FILE__),"..","sipper")


require 'driven_sip_test_case'
require 'stringio'


class TestStringRecord < DrivenSipTestCase

 def setup
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "test_controllers", "string")
    super
  end
  
  def test_string_record
    start_named_controller("StringRecord::UacController", true)
    sleep 1  #todo can you fix these sleeps
    
    record_in = get_in_recording( 0 )
    record_out = get_out_recording( 0 )
    
    # uac
    assert_equal("> INFO", record_out.get_recording[0])
    assert_equal("< 200", record_out.get_recording[1])
    
    #uas
    assert_equal("< INFO", record_in.get_recording[0])
    assert_equal("> 200", record_in.get_recording[1])
  end
    
end
