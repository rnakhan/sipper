require 'sip_test_driver_controller'

module CancelCase
  class UasCancelController < SIP::SipTestDriverController
  
     def on_invite(session)
       unless session['response_sent']
         session.local_tag = 5  #to differentiate the key for UAC/UAS
         r = session.create_response(100, "Trying")
         sleep 0.1
         session.send(r)
         logd("Sent response from #{name}")
       else
         session['response_sent'] = true
       end
     end
     
     def on_cancel(session)
       logd("Received CANCEL at #{name}")
       session.respond_with(200)
       session.invalidate(true)
     end
   
  end
end