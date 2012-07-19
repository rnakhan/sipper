# The UAC does not use the state machine but the UAS does, this example
# demonstrates the difference in coding style between the two 
# approaches

module Smc
  class UacMessageController < SIP::SipTestDriverController
  
    def start
      u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
      u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
      logd("Sent a new request from uac_controller")
      u[:state] = "invite"
    end
    
    def on_success_res(session)
      if session[:state] == "invite"
        logd("Creating ACK on getting 200 OK")
        session.create_and_send_ack
      end
      session.request_with("message")
      session[:state] = "message"
    end
    
    def on_bye(session)
      if session[:state] == "message"
        session.respond_with 200
        session.invalidate
      else
        logw("Got BYE in wrong state")
      end
    end
    
  end
end
