require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#

require 'transport/base_transport'


class TestSmoke < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasSmokeController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        emit_console true 
        
        def on_invite(session)
          session.make_new_offer
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestSmoke")
        end
        
        def order
          0
        end
        
      end
      
      class UacSmokeController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.offer_answer.make_new_offer
          #r.sdp = SDP::SdpGenerator.make_no_media_sdp
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
    set_controller("SipInline::UacSmokeController")
  end
  
  
  def test_smoke_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end


