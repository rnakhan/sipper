
require 'driven_sip_test_case'


class TestFreeze < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasFrController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.do_record(session.irequest.content_length.to_s)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestFreeze")
        end
        
        def order
          0
        end
        
      end
      
      class UacFrController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.content_length = '10'
          r.content_length.freeze
          r.content_length = '20'
          m = u.send(r)
          u.do_record(m.content_length.to_s)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacFrController")
  end
  
  
  def test_fr_controllers
    self.expected_flow = ["> INVITE", "! 10", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! 10", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end