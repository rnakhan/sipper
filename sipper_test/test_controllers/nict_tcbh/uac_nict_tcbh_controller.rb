require 'transaction_handlers/app_nict_handler'

module SipNict
  class UacNictTcbhController < SIP::SipTestDriverController
      
    transaction_usage :use_transactions=>false, :use_nict=>true
    transaction_handlers :Nict=>AppNictHandler
    #start_on_load :true
    
    def start
      u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
      u.request_with("info", "sip:nasir@sipper.com", :p_session_record=>"msg-debug")
      logd("Sent a new INFO from #{name}")
    end
 
    def on_success_res(session)
      logd("Received response in #{name}")
      if session.iresponse.test_response_header
        logd("Test-Response-Header found in the response")
        session.request_with("message")
      end
      session.invalidate
    end
        
  end
end
