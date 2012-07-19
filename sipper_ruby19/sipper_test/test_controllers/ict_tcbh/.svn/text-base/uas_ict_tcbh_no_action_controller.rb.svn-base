require 'sip_test_driver_controller'

module SipIct
  
  class  UasIctTcbhNoActionController < SIP::SipTestDriverController
  
    def on_invite(session)
      logd("Received INVITE in #{name}")
      session.local_tag = 5  #todo differentiate automatically on the same container somehow
      session.respond_with(400)
    end
    
    def on_ack(session)
      session.invalidate
      session.flow_completed_for("TestControllerUsingIctWithTcbhNoAction")
    end
        
    def order
      0
    end
    
    def interested?(r)
      if r.test_name.to_s == "TestControllerUsingIctWithTcbhNoAction"
        true
      else
        false
      end
    end
    
  end
end
