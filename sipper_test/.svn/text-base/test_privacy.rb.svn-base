
require 'driven_sip_test_case'
require 'sdp/sdp_generator'

class TestPrivacy < DrivenSipTestCase

  def setup
    super
       
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    require 'b2bua_controller'
    
    module TestPrv_SipInline
      class UasPrvController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          if !session.irequest[:call_info] and !session.irequest[:history_info] and !session.irequest[:in_reply_to] and !session.irequest[:organization] and !session.irequest[:p_asserted_identity] and !session.irequest[:reply_to] and !session.irequest[:subject] and !session.irequest[:user_agent]  
            session.do_record("recommended_headers_deleted")
          else
            session.do_record("recommended_headers_not_deleted")  
          end
          
          if session.irequest.from.uri == "sip:anonymous@anonymous.invalid" and session.irequest.from.display_name == '"Anonymous"' and session.irequest.call_id != "123@sipper.com" and session.irequest.contact != "sip:sipper.com"
            session.do_record("recommended_headers_anonymized")
          else
            session.do_record("recommended_headers_not_anonymized")  
          end          
          r = session.create_response(200)
          r.privacy = "user"
          r.call_info = "efg"
          r.history_info = "efg"
          r.organization = "efg"
          r.p_asserted_identity = "sip:efg.com"
          r.record_route = "sip:efg.com"
          r.reply_to = "efg"
          r.server = "efg"
          r.warning = '301 isi.edu "Incompatible network address type "E.164""'
          session.send(r)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
        end
        

        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
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
          r = apply_privacy(r)
          # Assuming element is not trusted, so removing the P-Asserted-Identity 
          r.p_asserted_identity = nil           
          r.p_controller = "uas"
          r.p_session_record = 'msg-info'
          peer.send r
        end


        def on_success_res(session)
          apply_privacy(session.iresponse)
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
      
      
      class UacPrvController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r.add_privacy("user").add_privacy("header").add_privacy("session").add_privacy("history").add_privacy("id") 
          r.p_controller = "b2bua"
          r.call_id = "123@sipper.com"
          r.contact = "sip:sipper.com"
          r.call_info = "abc"
          r.history_info = "abc"
          r.in_reply_to = "abc"
          r.organization = "abc"
          r.p_asserted_identity = "sip:abc.com"
          r.record_route = "sip:abc.com"
          r.add_record_route("sip:mno.com")
          r.referred_by = "sip:abc.com"
          r.reply_to = "abc"
          r.subject = "abc"
          r.user_agent = "abc"
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res_for_invite(session)
          if !session.iresponse[:call_info] and !session.iresponse[:history_info] and !session.iresponse[:organization] and !session.iresponse[:p_asserted_identity] and !session.iresponse[:reply_to] and !session.iresponse[:server]
            session.do_record("recommended_headers_deleted")
          else
            session.do_record("recommended_headers_not_deleted")  
          end
          if session.iresponse.warning == '301 "Incompatible network address type "E.164""'
            session.do_record("recommended_header_anonymized")
          else
            session.do_record("recommended_header_not_anonymized")  
          end
          session.request_with('ACK')
          session.request_with("bye")
        end

        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestPrivacy")
        end
        
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestPrv_SipInline::UacPrvController")
  end
  
  
  def test_rt1_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! recommended_headers_deleted", "! recommended_header_anonymized", "> ACK", "> BYE", "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE",  "> 100 ", "! recommended_headers_deleted", "! recommended_headers_anonymized", "> 200", "< ACK", "< BYE", "> 200"]
    verify_call_flow(:in,1)
  end
  
  
end


