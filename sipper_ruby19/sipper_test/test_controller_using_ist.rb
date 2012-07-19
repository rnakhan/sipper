require 'driven_sip_test_case'

class TestControllerUsingIst < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasIstController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_ist=>true
        transaction_timers :t1=>#{@grty*2}
        session_timer #{@grty*10}
        def on_invite(session)
          logd("Received INVITE in "+name)
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          r = session.create_response(400, "Bad Request")
          session.send(r)
          session.invalidate
        end
        
        
        def order
          0
        end
      end
      
      class UacIstController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer #{@grty*20}
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_failure_res(session)
          logd("Received response in "+name)
          if session['act']
            session.create_and_send_ack  # we are doing this because no ICT  
            session.invalidate
            session.flow_completed_for("TestControllerUsingIst")  
          else
            session['act'] = true
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacIstController")
  end
  
  
  def test_ist_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 400 {2,2}", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 400 {2,2}", "< ACK {0,1}"]  # 100 & 400 retrans sent by txn also ACK recvd by Txn
    verify_call_flow(:in)
  end
  
end

