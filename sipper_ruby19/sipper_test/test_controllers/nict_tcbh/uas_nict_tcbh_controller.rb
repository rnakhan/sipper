require 'sip_test_driver_controller'

module SipNict
  class  UasNictTcbhController < SIP::SipTestDriverController
    def on_info(session)
      logd("Received INFO in #{name}")
      session.local_tag = 5  #todo differentiate automatically on the same container somehow
      session.respond_with(200)
    end
    
    def on_message(session)
      session.invalidate
      session.flow_completed_for("TestControllerUsingNictWithTcbh")
    end
        
    def order
      0
    end
  end
end