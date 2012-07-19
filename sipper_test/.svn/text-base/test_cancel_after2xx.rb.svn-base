
require 'driven_sip_test_case'

# The Client sends a CANCEL to INVITE after a 2xx response. lax setting required for this.
#  The UAS does not use transactions so no 481 response will be sent. 

class TestCancelAfter2xx < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasCancel3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE in #{name} sent a 200")
        end
        
        def on_cancel(session)
          session.respond_with(200)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacCancel3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        transaction_timers :ty=>150      
        session_timer 300 
        
        def start
          SipperConfigurator[:ProtocolCompliance] = 'lax'
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
          u.create_and_send_cancel_when_ready
        end
     
        def on_failure_res(session)
          logd("Received failure response in #{name}")
          session.do_record("FAILURE 408 is not expected here")
        end
        
        def on_success_res(session)
          logd("Received success response in #{name}")
          if session.iresponse.get_request_method == "CANCEL"
            session.invalidate(true)
            session.flow_completed_for("TestCancelAfter2xx")
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacCancel3Controller")
  end
  
  
  def test_cancel3_controllers
    self.expected_flow = ["> INVITE", "< 200", "> CANCEL", "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200", "< CANCEL", "> 200"] 
    verify_call_flow(:in)
  end
  
end

