
require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#
class TestResponseWithoutToTag < DrivenSipTestCase

  def setup
    super
    @pc = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance] = 'lax'
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasWttController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          r = session.create_response(200)
          r.to.tag = nil
          r.to.bb = nil
          session.send r
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestResponseWithoutToTag")
        end
        
        def order
          0
        end
        
      end
      
      class UacWttController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r.to.bb = 'x'
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          if session.iresponse.to
            session.do_record('no_to_tag')
          else
            session.do_record('has_to_tag')
          end
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
    set_controller("SipInline::UacWttController")
  end
  
  
  def test_wtt_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! no_to_tag", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end 
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @pc
    super
  end
end
