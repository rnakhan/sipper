
require 'driven_sip_test_case'
require 'sdp/sdp_generator'

class TestB2bua1 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    require 'b2bua_controller'
    
    module TestB2bua1_SipInline
      class UasB2buaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.name = "uas"
          r = session.create_response(200)
          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          session.send(r)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestB2bua1")
        end
        
        def order
          1
        end
        
        def interested?(req)
          req.p_controller == "uas"
        end
        
      end
      
      
      class TestB2buaController < SIP::B2buaController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.name = "b2buas"
          peer = get_or_create_peer_session(session, SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          peer.name = "b2buac"
          r = create_b2bua_request(session)
          r.p_controller = "uas"
          r.p_session_record = nil
          peer.send r
        end


        def on_success_res(session)
          relay_response(session)
          if session.iresponse.get_request_method == "BYE"
            invalidate_sessions(session, true)
          end
        end

        def on_ack(session)
          relay_request(session)
        end
        
        def on_bye(session)
          relay_request(session)
        end
        
        def interested?(req)
          req.p_controller == "b2bua"
        end
        
        def order
          0
        end
        
      end
      
      
      class UacB2buaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.name = "uac"
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
    set_controller("TestB2bua1_SipInline::UacB2buaController")
  end
  
  
  def test_b2bua
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
  
end


