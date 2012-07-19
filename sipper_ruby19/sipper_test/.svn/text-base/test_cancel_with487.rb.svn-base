
require 'driven_sip_test_case'

class TestCancelWith487 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasCancel1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          logd("Received INVITE in "+name)
			logd("not doing anything")
        end
        
        def on_cancel(session)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacCancel1Controller < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true        
        session_timer 100
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
          u.create_and_send_cancel_when_ready
        end
     
        def on_failure_res(session)
          logd("Received failure response in "+name)
          session.invalidate
          session.flow_completed_for("TestCancelWith487") 
        end
        
        def on_success_res(session)
          logd("Received success response in "+name)
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacCancel1Controller")
  end
  
  
  def test_cancel1_controllers
    self.expected_flow = ["> INVITE", "< 100", "> CANCEL", "< 200", "< 487", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "< CANCEL", "> 200", "> 487", "< ACK {0,}"] 
    verify_call_flow(:in)
  end
  
end


