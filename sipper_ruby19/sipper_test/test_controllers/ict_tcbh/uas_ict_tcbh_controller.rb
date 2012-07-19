require 'sip_test_driver_controller'

module SipIct
  class  UasIctTcbhController < SIP::SipTestDriverController
    def on_invite(session)
      logd("Received INVITE in #{name}")
      session.local_tag = 5  #todo differentiate automatically on the same container somehow
      session.respond_with(200)
    end
    
    def on_info(session)
      session.invalidate
      session.flow_completed_for("TestControllerUsingIctWithTcbh")
    end
        
    def order
      0
    end
    
    def interested?(r)
      if r.test_name.to_s == "TestControllerUsingIctWithTcbh"
        true
      else
        false
      end
    end
    
  end
end