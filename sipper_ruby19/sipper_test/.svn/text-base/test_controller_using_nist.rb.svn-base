require 'driven_sip_test_case'

class TestControllerUsingNist < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasNistController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_nist=>true
        transaction_timers :t1=>100
        
        def on_info(session)
          logd("Received INFO in "+name)
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          r = session.create_response(400, "Bad Request")
          session.send(r)
          session.invalidate(true)
        end
        
        
        def order
          0
        end
      end
      
      class UacNistController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 200
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from "+name)
        end
     
        def on_failure_res(session)
          logd("Received response in "+name)
          session.invalidate
          session.flow_completed_for("TestControllerUsingNist")  
        end
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacNistController")
  end
  
  
  def test_ist_controllers
    self.expected_flow = ["> INFO", "< 400"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INFO", "> 400"]
    verify_call_flow(:in)
  end
  
end

