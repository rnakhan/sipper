require 'base_controller'


module StringRecord

  class UacController < SIP::BaseController
    
     #start_on_load :true
     
     def initialize
       logd("UAC controller created")
     end
     
     def start
       r = Request.create_initial("info", "sip:nasir@sipper.com",  :p_session_record=>"msg-info")
       u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
       u.record_io = yield  if block_given?
       u.send(r)
       logd("Sent a new request from uac_controller")
     end
     
     def on_success_res(session)
       logd("Received response in the uac_controller")
       session.invalidate(true)
       session.flow_completed_for("TestStringRecord")
     end
  end
  
end