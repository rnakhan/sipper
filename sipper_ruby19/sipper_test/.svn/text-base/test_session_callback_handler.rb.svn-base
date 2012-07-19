require 'driven_sip_test_case'

class TestSessionCallbackHandler < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasScbhController < SIP::SipTestDriverController
        def on_invite(session)
          logd("Received INVITE in "+name)
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          r = session.create_response(200, "OK")
          session.send(r)
          session.invalidate
        end
        
        def order
          0
        end
      end
      class UacScbhController < SIP::SipTestDriverController
      
        session_timer 500
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          # session.session_timer = 200 (alternatively used the directive)
          session.invalidate
          session.flow_completed_for("TestSessionCallbackHandler")
        end
        
        def session_being_invalidated_ok_to_proceed?(session)
          if session['once']
            return true
          else
            session['once'] = true  
            session.session_timer = 200
            session.do_record("InvalidateHandler")
            return false
          end
        end
        
      end 
    end 
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacScbhController")
  end
  
  
  def test_scbh_controller
    self.expected_flow = ["> INVITE", "< 200", "! InvalidateHandler"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200"]
    verify_call_flow(:in)
  end
  
end
