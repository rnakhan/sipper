

require 'driven_sip_test_case'

class TestDigestChallenge2 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasDigest2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          if session.irequest[:proxy_authorization]
            session.respond_with(200)
          else
            r = session.create_response(407)
            r.proxy_authenticate = 'Digest realm="atlanta.com", domain="sip:ss1.carrier.com", nonce="f84f1cec41e6cbe5aea9c8e88d359", stale=FALSE, algorithm=MD5'
            session.send r
          end  
        end
        
        
        def on_ack(session)
          last_sent = session.get_state_array[-2]
          session.request_with 'BYE' if last_sent == "sent_200"
        end
        
        def on_success_res(s)
          s.invalidate(true)
          s.flow_completed_for("TestDigestChallenge2")
        end
        
        def order
          0
        end
        
      end
      
      class UacDigest2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_failure_res(session)
          if session.iresponse.code == 407
            r = session.create_request_with_response_to_challenge(session.iresponse.proxy_authenticate, true,
                 "sipper_user", "sipper_passwd")
            r.proxy_authorization.cnonce = nil
            session.send(r)
          end
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
    set_controller("SipInline::UacDigest2Controller")
  end
  
  
  def test_digest_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 407", "> ACK", "> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 407", "< ACK", "< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end