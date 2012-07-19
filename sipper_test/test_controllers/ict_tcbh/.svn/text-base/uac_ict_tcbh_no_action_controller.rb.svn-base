
require 'transaction_handlers/app_ict_handler'

module SipIct
  class UacIctTcbhNoActionController < SIP::SipTestDriverController
      
    transaction_usage :use_transactions=>false, :use_ict=>true
    transaction_handlers :Ict=>AppIctHandlerNoAction
    #start_on_load :true
    
    def start
      u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
      u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info",
                     :test_name=>"TestControllerUsingIctWithTcbhNoAction")
      logd("Sent a new INVITE from #{name}")
    end
 
    # even though we have the transaction we will create the ACK here as we have a
    # no action tcbh. 
    def on_failure_res(session)
      logd("Received response in #{name}")
      session.create_and_send_ack
      session.invalidate
    end
        
  end
end

