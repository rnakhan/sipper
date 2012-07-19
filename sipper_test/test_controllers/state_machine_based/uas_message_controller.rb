require 'CreditControl_sm'

module Smc
  class UasMessageController < SIP::SipTestDriverController
  
    def on_invite(session)
      session[:sm] = SipCreditControl_sm.new(self) unless session[:sm]
      session[:sm].invite
      session.local_tag = 5  #to differentiate the key for UAC/UAS
      session.respond_with(200)
      logd("Sent response from #{name}")
      session[:sm].success
    end
    
    def on_message(s)
      s[:sm].message(s)
    end
    
    def on_success_res(s)
      s.invalidate
      s.flow_completed_for("TestSmcController") 
    end

    #--------SM callbacks--------     
    def check_credit(s)
      (s.remote_cseq)%3!=0
    end
     
    def send_success(s)
      s.respond_with(200)
    end

    def send_bye(s)
      s.request_with "bye"
    end
    
    def cleanup(s)
      #nothing to cleanup here as we want to signal on 2xx callback, invalidating here
      #would remove the session which would not allow the response to reach us. 
    end
    #--------SM callbacks--------      
 
  end
end
