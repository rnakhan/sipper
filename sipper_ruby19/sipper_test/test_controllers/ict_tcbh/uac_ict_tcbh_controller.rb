require 'transaction_handlers/app_ict_handler'

module SipIct
  class UacIctTcbhController < SIP::SipTestDriverController
      
    transaction_usage :use_transactions=>false, :use_ict=>true
    transaction_handlers :Ict=>AppIctHandler
    #start_on_load :true
    
    def start
      u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
      u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-debug",
                     :test_name=>"TestControllerUsingIctWithTcbh")
      logd("Sent a new INVITE from #{name}")
    end
 
    def on_success_res(session)
      logd("Received response in #{name}")
      if session.iresponse.test_response_header
        logd("Test-Response-Header found in the response")
        session.request_with("info")
      end
      session.invalidate
    end
        
  end
end
