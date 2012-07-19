require 'sip_test_driver_controller'

module CancelCase
  class UacCancelController < SIP::SipTestDriverController
    
     #start_on_load  :true
     transaction_usage :use_transactions=>true
     def start
       r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
       u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
       u.send(r)
       logd("Sent a new request from uac_controller")
       r = u.create_cancel
       begin
         u.send(r)
       rescue RuntimeError => e
         logd("Exception while sending CANCEL")
         u.do_record("Exception while sending CANCEL")
       end
     end
     
     def on_trying_res(session)
       logd("Creating CANCEL on getting 100 Trying")
       r = session.create_cancel
       session.send(r)  
     end
     
     def on_success_res(session)
       logd("Got a 200 response in UAC for TestCancel")
       session.invalidate
       session.flow_completed_for("TestCancel")
     end
     
  end
end