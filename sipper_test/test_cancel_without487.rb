
require 'driven_sip_test_case'

# The Client sends a CANCEL to INVITE but never gets the 487/INVITE, but it should still timeout
# according to timer Y.
# Note that there is no ACK here because the408 response is locally generated on transaction timeout
# and ICT transaction is terminated. 

class TestCancelWithout487 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasCancel2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        def on_invite(session)
          session.respond_with(100)
          logd("Received INVITE in #{name} not doing anything")
        end
        
        def on_cancel(session)
          session.respond_with(200)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacCancel2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        transaction_timers :ty=>#{@grty*4}      
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
          u.create_and_send_cancel_when_ready
        end
     
        def on_failure_res(session)
          logd("Received failure response in #{name}")
          session.invalidate(true)
          session.flow_completed_for("TestCancelWithout487")  
        end
        
        def on_success_res(session)
          logd("Received success response in #{name}")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacCancel2Controller")
  end
  
  
  def test_cancel1_controllers
    self.expected_flow = ["> INVITE", "< 100", "> CANCEL", "< 200", "< 408"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "< CANCEL", "> 200"] 
    verify_call_flow(:in)
  end
  
end
