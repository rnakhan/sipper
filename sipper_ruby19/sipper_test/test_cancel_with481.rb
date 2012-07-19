
require 'driven_sip_test_case'

# Client sends a CANCEL after getting 1xx/INVITE but in the meantime server also sends a 2xx 
# thereby clearing the transaction on the server. The CANCEL does not find a Stx and thus 
# should be responded to by a 481.  

class TestCancelWith481 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestCancelWith481_SipInline
      class UasCancel4Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true 
        transaction_timers :tz=>0  # terminate immediately
        session_timer #{@grty*6}
        
        def on_invite(session)
          session.respond_with(200)
          session.invalidate
          logd("Received INVITE in "+name)
		  logd("sent a 200")
        end
       
        
        def order
          0
        end
        
      end
      
      class UacCancel4Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        session_timer #{@grty*6}
        
        def start
          SipperConfigurator[:ProtocolCompliance] = 'lax'
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
       
        
        def on_failure_res(session)
          logd("Received failure response in "+name)
          session.invalidate
          session.flow_completed_for("TestCancelWith481")
        end
        
        def on_success_res(session)
          logd("Received success response in "+name)
          if session.iresponse.get_request_method == "INVITE"
            sleep #{@grty}/1000.0 # make sure IST terminates
            session.send(session.create_cancel) unless session['cancel_sent']
            session['cancel_sent'] = true
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestCancelWith481_SipInline::UacCancel4Controller")
  end
  
  
  def test_cancel3_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> CANCEL", "< 481"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< CANCEL", "> 481"] 
    verify_call_flow(:in)
  end
  
end


