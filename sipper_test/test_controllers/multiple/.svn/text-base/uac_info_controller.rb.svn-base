require 'blank_test'

module InfoTest
  class UacInfoController < SIP::BaseController
  
     def start
       r = Request.create_initial("info", "sip:nasir@agnity.com", :p_session_record=>"msg-info")
       u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
       u.send(r)
       logd("Sent a new request from #{name}")
       b = BlankTest.new
     end
     
     def on_success_res(session)
       logd("Received response in #{name}")
       session.invalidate(true) 
       session.flow_completed_for("TestMultiple")
     end
     
  end
end
