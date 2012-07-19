require 'base_controller'

module SipMessage
  class UacMsgController < SIP::BaseController
  
     def start
       r = Request.create_initial("message", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
       u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
       u.send(r)
       logd("Sent a new request from #{name}")
     end
     
     def on_success_res(session)
       logd("Received response in #{name}")
       session.invalidate(true) 
       session.flow_completed_for("TestMultiple")
     end
     
  end
end
