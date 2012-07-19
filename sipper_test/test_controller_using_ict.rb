require 'driven_sip_test_case'

class TestControllerUsingIct < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasIctController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false
        def on_invite(session)
          logd("Received INVITE in #{name}")
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          if session['ignored']
            r = session.create_response(200, "OK") 
            session.send(r)
            session.invalidate(true) 
          else
            session['ignored'] = true
          end
        end
        
        def order
          0
        end
      end
      
      class UacIctController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_ict=>true
        transaction_timers :t1=>#{@grty*2}  # just want at least one retransmit
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          session.invalidate(true)
          session.flow_completed_for("TestControllerUsingIct")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacIctController")
  end
  
  
  def test_ict_controllers
    self.expected_flow = ["> INVITE {1,}", "< 200 {1,}"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE {2,2}", "> 200"]  # at least one retrans
    verify_call_flow(:in)
  end
  
end

