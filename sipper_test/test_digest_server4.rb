
require 'driven_sip_test_case'

class TestDigestServer4 < DrivenSipTestCase
  
  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasDigestS4Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        realm "my_sipper.com"
        authenticate_requests :invite
        
        
        def on_ack(session)
          states = session.get_state_array()
          if states[-2] == "sent_403"
            session.invalidate(true)
            session.flow_completed_for("TestDigestServer4")  
          end
        end
       
        
        def order
          0
        end
        
      end
      
      class UacDigestS4Controller < SIP::SipTestDriverController
      
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
                 "test_user", "sipper_passwd")     
            session.send r
          elsif  session.iresponse.code == 403
            session.invalidate(true)
          end
        end      
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacDigestS4Controller")
  end
  
  
  def test_digest_controllers
    self.expected_flow = ["> INVITE", "< 401", "> ACK", "> INVITE", "< 403", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 401", "< ACK", "< INVITE", "> 403", "< ACK"]
    verify_call_flow(:in)
  end
end