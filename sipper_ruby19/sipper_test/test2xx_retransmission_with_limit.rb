
require 'driven_sip_test_case'

class Test2xxRetransmissionWithLimit < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class Uas2xxLimitController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        t2xx_usage true
        
        # increased by a factor of 2
        t2xx_timers :Start=>200, :Cap=>400, :Limit=>1500
        
        session_timer 100
        
        def on_invite(session)
          logd("Received INVITE in "+name)
          session.local_tag = 7  
          r = session.create_response(200, "OK")
          session.send(r)
        end
        
        def no_ack_received(session)
          session.do_record("NO_ACK")
          session.invalidate
          session.flow_completed_for("Test2xxRetransmissionWithLimit")  
        end
        
        def order
          0
        end
      end
      
      class Uac2xxLimitController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
        
        def on_success_res(session)
          if session['count']
            session['count'] = session['count']+1
            session.invalidate if session['count'] == 4            
          else
            session['count'] = 1
          end
        end
        
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::Uac2xxLimitController")
  end
  
  
  def test_2xx_retransmission_timeout
    self.expected_flow = ["> INVITE","< 200 {4,5}"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200 {4,5}", "! NO_ACK"] 
    verify_call_flow(:in)
  end
  
end



