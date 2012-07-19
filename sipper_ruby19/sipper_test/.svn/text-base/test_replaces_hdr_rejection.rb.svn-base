require 'driven_sip_test_case'


class TestReplaceFailure < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasRpController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          last_resp = session.get_state_array[-2]
          session.request_with("bye") if last_resp == "sent_200"
        end
        
        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestReplaceFailure")
        end
        
        def order
          0
        end
        
      end
      
      class UacRpController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("INVITE", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.replaces = "123@nasir.sipper.com;from-tag=23431;to-tag=1234567" 
          r.join = "123@nishant.sipper.com;from-tag=2331;to-tag=3567"
          u.send(r)
        end
     
        def on_failure_res(session)
          if !session['4xx']
           #session.invalidate(true) 
           #new_session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
           #new_session.continue_recording_from session
           #r = new_session.create_initial_request("INVITE", "sip:nasir@sipper.com")
           #r.replaces = "123@nasir.sipper.com;from-tag=23431;to-tag=1234567"
           #r.join = "123@nishant.sipper.com;from-tag=2331;to-tag=3567"
           #new_session.send(r)
           #new_session['4xx'] = 1          
          #elsif session['4xx'] == 1           
           r = session.create_subsequent_request("INVITE", "sip:nasir@sipper.com")
           r.replaces = "123@nasir.sipper.com;from-tag=23431;to-tag=1234567" 
           r.add_replaces("123@nishant.sipper.com;from-tag=2331;to-tag=3567")
           session.send(r)
           session['4xx'] = 1          
          elsif session['4xx'] == 1           
           r = session.create_subsequent_request("INVITE", "sip:nasir@sipper.com")
           session.send(r)
          end  
        end
        
        def on_success_res_for_invite(session)
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
    set_controller("SipInline::UacRpController")
  end
  
  
  def test_replace_controllers
    self.expected_flow = ["> INVITE", "< 100 {0,}", "< 400", "> ACK", "> INVITE", "< 100 {0,}", "< 400", "> ACK", "> INVITE" , "< 100 {0,}", "< 200", "> ACK", "< BYE", "> 200"] 
    start_controller
    verify_call_flow(:out)  
    self.expected_flow = ["< INVITE", "> 100", "> 400", "< ACK", "< INVITE", "> 100", "> 400", "< ACK", "< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
    
  end
end