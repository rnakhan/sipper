

require 'driven_sip_test_case'


class TestSessionStates < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasSsController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.get_state_array.each do |s|
            session.do_record(s)
          end
          session.respond_with(200)
          session.do_record(session.last_state)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestSessionStates")
        end
        
        def order
          0
        end
        
      end
      
      class UacSsController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          u.do_record(u.last_state)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.do_record(session.last_state)
          session.request_with('ACK')
        end
        
        def on_provisional_res(session)
          session.do_record(session.last_state)
        end
        
        def on_bye(session)
          session.get_state_array.each do |s|
            session.do_record(s)
          end
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacSsController")
  end
  
  
  def test_ss
    self.expected_flow = ["> INVITE", "! sent_invite", "< 100", "< 200", "! received_200", "> ACK", "< BYE", "! initial", "! sent_invite","! received_100", "! received_200", "! sent_ack",  "! received_bye", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! initial", "! received_invite", "! sent_100", "> 200", "! sent_200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  

  
end