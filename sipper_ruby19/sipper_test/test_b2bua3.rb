
require 'driven_sip_test_case'

class TestB2bua3 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    require 'b2bua_controller'
    
    module SipInline
      class UasB2bua31Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        session_timer 1000
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate
          session.flow_completed_for("TestB2bua3")
        end
        
        def order
          1
        end
        
        def interested?(req)
          req.p_controller == "uas31"
        end
        
      end
      
      class UasB2bua30Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        session_timer 1000
        
        def on_invite(session)
          session.respond_with(400)
          logd("Received INVITE sent a 400 from "+name)
        end
        
        def on_ack(session)
          session.invalidate(true)  
        end
        
        
        def order
          2
        end
        
        def interested?(req)
          req.p_controller == "uas30"
        end
        
      end
      
      
      class TestB2bua3Controller < SIP::B2buaController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          peer = get_or_create_peer_session(session, SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = create_b2bua_request(session, session.irequest)
          r.p_controller = "uas30"
          r.p_session_record = nil
          peer.send r
          session['orig_invite'] = r
        end
        
        def on_failure_res(session)
          orig_anchor = get_peer_session(session)
          orig_invite = orig_anchor.irequest
          peer = create_peer_session(orig_anchor, SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = create_b2bua_request(orig_anchor, orig_invite)
          r.p_controller = "uas31"
          r.p_session_record = nil
          sleep 1
          peer.send r          
          session.invalidate(true)  # get rid of first UAS session
        end
        
        def on_success_res(session)
          relay_response(session)
          if session.iresponse.get_request_method == "BYE"
            invalidate_sessions(session, true)
          end
        end
        
        def on_bye(s)
          relay_request(s)
        end
        
        def on_ack(s)
          relay_request(s)
        end
        
        def interested?(req)
          req.p_controller == "b2bua"
        end
        
        def order
          0
        end
        
      end
      
      
      class UacB2bua3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
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
    set_controller("SipInline::UacB2bua3Controller")
  end
  
  
  def test_b2bua3
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
end


