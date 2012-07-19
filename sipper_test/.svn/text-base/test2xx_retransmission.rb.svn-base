
require 'driven_sip_test_case'

class Test2xxRetransmission < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module Test2xxRetransmission_SipInline
      class Uas2xxController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        t2xx_usage true
        
        t2xx_timers :Start=>100
        
        session_timer 500
        
        def on_invite(session)
          logd("Received INVITE in #{name}")
          session.local_tag = 6  #todo differentiate automatically on the same container somehow
          r = session.create_response(200, "OK")
          session.send(r)
        end
        
        def on_ack(session)
          session.invalidate
          session.flow_completed_for("Test2xxRetransmission")  
        end
        
        def order
          0
        end
      end
      
      class Uac2xxController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          if session['act']
            session.create_and_send_ack 
            session.invalidate
          else
            session['act'] = true
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("Test2xxRetransmission_SipInline::Uac2xxController")
  end
  
  
  def test_2xx_retransmissions
    self.expected_flow = ["> INVITE","< 200 {2,}", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200 {2,2}", "< ACK"]
    
    verify_call_flow(:in)
  end
  
end


