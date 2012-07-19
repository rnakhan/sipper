require 'driven_sip_test_case'

class TestSessionLifetime < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    
    module SipInline
    
      class UasSltController < SIP::SipTestDriverController
        def on_invite(session)
          logd("Received INVITE in #{name}")
          session.local_tag = 5 
          r = session.create_response(200, "OK")
          session.send(r)
          session.invalidate
        end
        
        def order
          0
        end
      end
      
      
      class UacSltController < SIP::SipTestDriverController
      
        session_timer 300
        session_limit 1000
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          session.invalidate
          session.flow_completed_for("TestSessionLifetime")
        end
        
        def session_being_invalidated_ok_to_proceed?(session)
          session.do_record("Life")
          return false
        end
        
      end 
    end 
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacSltController")
  end
  
  
  def test_slt_controller
    self.expected_flow = ["> INVITE", "< 200", "! Life {3,3}"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200"]
    verify_call_flow(:in)
  end
  
end
