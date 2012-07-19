
require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#
class TestSessionStateUserDefined < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasSudController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.respond_with(200)
          session.do_record(session.last_state)
          session.set_state("my_state")
          session.do_record(session.last_state)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.do_record(session.get_state_array.length.to_s)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.do_record(session.last_state)
          session.invalidate(true)
          session.flow_completed_for("TestSessionStateUserDefined")
        end
        
        def order
          0
        end
        
      end
      
      class UacSudController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
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
    set_controller("SipInline::UacSudController")
  end
  
  
  def test_smoke_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "! sent_200", "! my_state",  "< ACK", "! 1", "> BYE", "< 200", "! my_state"]
    verify_call_flow(:in)
  end

  
end

