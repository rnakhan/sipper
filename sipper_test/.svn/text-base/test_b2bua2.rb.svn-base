# In this b2bua the b2bua controller goes transparent after sending the request
# it relies on session_limit setting to invalidate as in transparent mode it does
# not get a chance to do that. Alternatively it could have used a session timer 
# and would have invalidated right after sending the invite.
# 
# As this is transparent b2bua it will relay every single message including 100 trying
# so this is made not to use transactions. (Otherwise there would be two 100 responses
# coming out of this, one from transaction SM and one from controller relaying. 
# 
# Transparent b2buas however can use transactions but then they will have to either relay
# conditionally themselved or go transparent after say they have received a 100 trying 
# response. 

require 'driven_sip_test_case'

class TestB2bua2 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    require 'b2bua_controller'
    
    module SipInline
      class UasB2bua2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        session_record "msg-info"
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestB2bua2")
        end
        
        def order
          1
        end
        
        def interested?(req)
          req.p_controller == "uas"
        end
        
      end
      
      
      class TestB2bua2Controller < SIP::B2buaController
      
        transaction_usage :use_transactions=>false
        session_limit 700
        
        def on_invite(session)
          peer = get_or_create_peer_session(session, SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = create_b2bua_request(session, session.irequest)
          r.p_controller = "uas"
          peer.send r
          go_transparent(session, true)
        end
        
        def interested?(req)
          req.p_controller == "b2bua"
        end
        
        def order
          0
        end
        
      end
      
      
      class UacB2bua2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        session_record "msg-info"
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r.p_controller = "b2bua"
          u.send(r)
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
    set_controller("SipInline::UacB2bua2Controller")
  end
  
  
  def test_b2bua2
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
end

