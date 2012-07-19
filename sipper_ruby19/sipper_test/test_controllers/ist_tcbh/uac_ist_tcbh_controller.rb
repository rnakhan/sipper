
module SipIst
  class UacIstTcbhController < SIP::SipTestDriverController
      
    transaction_usage :use_transactions=>false, :use_ict=>true
    
    #start_on_load :true
    
    def start
      u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
      u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-debug")
      logd("Sent a new INVITE from #{name}")
    end
 
    def on_success_res(session)
      logd("Received response in #{name}")
      session.request_with("ack")
      session.invalidate
    end
        
  end
end
