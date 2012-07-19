
require 'driven_sip_test_case'

# The client sends an INFO and after 183 gets a CANCEL and it gets responded to with a 200. 
# Later the INFO also gets a 200. So CANCEL has not impact on INFO transaction.  

class TestCancelWithNist < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestCancelWithNist_SipInline
      class UasCancel4Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_info(session)
          session.respond_with(183)
          logd("Received INFO in "+name)
			logd("sent a 183")
          session['info_request'] = session.irequest
        end
        
        def on_cancel(session)
          r = session.create_response(200, "OK", session['info_request'])
          session.send(r)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacCancel4Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        session_timer 300 
        
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from "+name)
          u.create_and_send_cancel_when_ready
        end
     
      
        
        def on_success_res(session)
          logd("Received success response in "+name)
          if session.iresponse.get_request_method == "CANCEL"
            session.do_record("200_CANCEL")
          else
            session.do_record("200_INFO")
            session.invalidate(true)
            session.flow_completed_for("TestCancelWithNist")
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestCancelWithNist_SipInline::UacCancel4Controller")
  end
  
  
  def test_cancel4_controllers
    self.expected_flow = ["> INFO", "< 183", "> CANCEL", "< 200", "! 200_CANCEL", "< 200", "! 200_INFO"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INFO", "> 183", "< CANCEL", "> 200 {2,2}"] 
    verify_call_flow(:in)
  end
 
  
end


