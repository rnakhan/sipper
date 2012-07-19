require 'sip_test_driver_controller'

class UasController < SIP::SipTestDriverController

   def initialize
     logd("#{name} controller created")
   end
   
   
   def on_success_res(session)
     logd("Received response in the #{name} controller")
   end
   
   def on_invite(session)
     logd("on_invite called for #{name}")
     if session.irequest.cseq.to_s =~ /2/
       r = session.create_response(200)
       session.send(r)
       session.do_record("Just before invalidation")
       session.invalidate(true)
       return
     end
     session.local_tag = 5  #todo differentiate the key for UAC/UAS
     r = session.create_response(200, "OK")
     r.contact = "sip:nasir@home.com"
     session.send(r)
     logd("Sent response from #{name}")
     sleep(1)
     r = session.create_subsequent_request("invite")
     logd("Sent another INVITE")
     session.send(r)
   end
 
end