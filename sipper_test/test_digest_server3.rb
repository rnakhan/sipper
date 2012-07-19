

require 'driven_sip_test_case'

class TestDigestServer3 < DrivenSipTestCase
  
  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasDigestS3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        realm "my_sipper.com"
        authenticate_requests :invite
        
        def on_invite(session)      
          session.respond_with(200)     
        end
        
        
        def on_ack(session)
          last_sent = session.get_state_array[-2]
          session.request_with 'BYE' if last_sent == "sent_200"   
        end
        
        def on_success_res(s)
          s.invalidate(true)
          s.flow_completed_for("TestDigestServer3")
        end
        
        def order
          0
        end
        
      end
      
      class UacDigestS3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true 
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_failure_res(session)
          if session.iresponse.code == 401
            r = session.create_request_with_response_to_challenge(session.iresponse.www_authenticate, false,
                 "sipper_user", "sipper_passwd")     
            session.send r
          end
        end
        
        
        def on_success_res(session)
          ack = session.create_ack
          ack.authorization = session[:authorization]
          session.send(ack)
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacDigestS3Controller")
  end
  
  
  def test_digest_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 401", "> ACK", "> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 401", "< ACK", "< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
end