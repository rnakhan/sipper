require 'sip_test_driver_controller'

class UacController < SIP::SipTestDriverController
  
   #start_on_load :true
   
   def initialize
     logd("UAC controller created")
   end
   def start
     ["msg-debug"].each do |level|
       1.times do
         r = Request.create_initial("invite", "sip:nasir@agnity.com", :p_asserted_identity=>"sip:nina@home.com", :p_session_record=>level)
         u = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:LocalTestPort])
         u.record_io = yield  if block_given?
         u.send(r)
         logd("Sent a new request from uac_controller")
       end
     end
   end
   
   def on_success_res(session)
     logd("Received response in the uac_controller")
     if session.iresponse.cseq.to_s =~ /2/
       session.invalidate(true)
       session.flow_completed_for("TestEte")
     end
   end
   
   def on_invite(session)
     logd("on_invite called for #{name}")
      r = session.create_response(200, "OK")
      session.send(r)
      sleep(0.02)
      r = session.create_subsequent_request("invite")
      session.send(r)
   end
 
end