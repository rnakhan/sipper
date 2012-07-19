
require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#
class TestEmptySdp < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasEsController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          r = session.create_response('180')
          r.content_type = 'application/sdp'
          r.content_length = "0"
          session.send(r)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestEmptySdp")
        end
        
        def order
          0
        end
        
      end
      
      class UacEsController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_provisional_res(session)
          if session.iresponse.content_type == "application/sdp" && 
            session.iresponse.content_length == "0"
            session.do_record("sdp_with_zero_length")  
          end
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacEsController")
  end
  
  
  def test_es
    self.expected_flow = ["> INVITE", "< 100", "< 180","! sdp_with_zero_length", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 180",  "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end
