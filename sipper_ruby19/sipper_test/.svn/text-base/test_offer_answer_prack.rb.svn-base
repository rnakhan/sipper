
require 'driven_sip_test_case'

class TestOfferAnswerPrack < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestOfferAnswerPrack_SipInline
      class Uas2xxController2 < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        session_timer 500

        def on_invite(session)
          logd("Received INVITE in "+name)
          session[:inviteReq] = session.irequest
          session.respond_with(100)
          res=session.create_response(183, nil, session[:inviteReq], true)
          res.sdp.media_lines[0].delete :a
          session.send_response(res)
          session['prackState'] = '183'
        end

        def on_prack(session)
          session.respond_with(200)
          if (session['prackState'] == '183')
             session.respond_reliably_with(180, session[:inviteReq])
             session['prackState'] = '180'
          else
             session.respond_with(200, session[:inviteReq])
          end
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestOfferAnswerPrack")  
        end
        
        def order
          0
        end
      end
      
      class Uac2xxController2 < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.offer_answer.make_new_offer(nil, "sendonly")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_trying_res(session)
        end

        def on_provisional_res(session)
          logd("Received provisional response ")
           response = session.iresponse
           if (response.rseq )
              logd("Sending prack")
              session.offer_answer.make_new_offer("G711A", "sendrecv")
              session.create_and_send_prack
           end
        end

        def on_success_res(session)
          logd("Received response in "+name)
          response = session.iresponse

          if session.iresponse.get_request_method == 'PRACK'
             logd("Received prack response")
          else
            session.create_and_send_ack 
            session.invalidate(true)
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestOfferAnswerPrack_SipInline::Uac2xxController2")
  end
  
  
  def test_prack
    self.expected_flow = ["> INVITE","< 100", "< 183", "> PRACK", "< 200", "< 180", "> PRACK", "< 200 {2,2}", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE","> 100", "> 183", "< PRACK", "> 200", "> 180", "< PRACK", "> 200 {2,2}", "< ACK"]
    
    verify_call_flow(:in)
  end
  
end


