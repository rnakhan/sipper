require 'driven_sip_test_case'

class TestIctWithTimeout < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    
    module SipInline
    
      class UasIctTimeoutController < SIP::SipTestDriverController
      
        def on_invite(session)
          logd("Received INVITE in "+name)
			logd("not doing anything")
          if session['count']
            session['count'] = session['count']+1
            session.invalidate if session['count']==7
          else
            session['count'] = 1
          end
        end
             
        def order
          0
        end
      end
      
      class UacIctTimeoutController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_ict=>true
        transaction_timers :t1=>100, :tb=>7000
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_failure_res(session)
          logd("Received response in "+name)
          session.invalidate
          session.flow_completed_for("TestIctWithTimeout")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacIctTimeoutController")
  end
  
  
  def test_ict_controllers
    self.expected_flow = ["> INVITE {6,7}", "< 408"] # transcation timeout
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE {6,7}"] 
    verify_call_flow(:in)
  end
  
end
