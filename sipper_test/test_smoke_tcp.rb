
require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#
class TestSmokeTcp < DrivenSipTestCase

  def setup
    @tp = SipperConfigurator[:LocalSipperTransports]
    SipperConfigurator[:LocalSipperTransports] = ["tcp_udp"]
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasSmokeTController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestSmokeTcp")
        end
        
        def order
          0
        end
        
      end
      
      class UacSmokeTController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          u = create_tcp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacSmokeTController")
  end
  
  
  def test_smoke_tcp_controllers
    self.expected_flow = ["> INVITE",  "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow()
  end

  def teardown
    SipperConfigurator[:LocalSipperTransports] = @tp
    super
  end
  
end
