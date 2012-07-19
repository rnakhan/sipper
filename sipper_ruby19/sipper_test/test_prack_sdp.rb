$:.unshift File.join(File.dirname(__FILE__),"..","sipper")
require 'driven_sip_test_case'

class TestPrackSdp < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestPrackSdp_SipInline
      class UasPrackSdpController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        t2xx_usage true
        
        t1xx_timers :Start=>100
        
        session_timer 500

        def on_invite(session)
          logd("Received INVITE in "+name)
          session.make_new_offer unless session.irequest.sdp
          session[:inviteReq] = session.irequest
          session.respond_with(100)
          
          r = session.create_response(183,"OK" ,session[:inviteReq], true)
          r.sdp.session_lines= {:s=> "nishant",:v=>"007"}
          # adding two new media lines with attributes
          r.sdp.add_media_lines({:m=>"audio 16000 RTP/AVP 0"})
          r.sdp.add_media_attribute_at(1,"sendonly")
          r.sdp.add_media_attribute_at(1,"rtpmap:0 PCMU/8000")
          r.sdp.add_media_lines({:m=>"video 16000 RTP/AVP 0"})
          r.sdp.add_media_attribute_at(2,"sendrecv")
          r.sdp.add_media_attribute_at(2,"rtpmap:101 telephone-event/8000")
          session.send(r)
        end

        def on_prack(session)
          if (session.irequest.sdp.session_lines[:t]=="55555555" and session.irequest.sdp.session_lines[:s]=="bansal" and session.irequest.sdp.session_lines[:v]=="12")
            session.do_record("modified_answer_received")
          else
            session.do_record("modified_answer_not_received")
          end
          session.respond_with(200)
          session.respond_with(200, session[:inviteReq])
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestPrackSdp")  
        end
        
        def order
          0
        end
      end
      
      class UacPrackSdpController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_provisional_res(session)
          if (session.iresponse.sdp.session_lines[:s]=="nishant" and session.iresponse.sdp.session_lines[:v]=="007" and session.iresponse.sdp.media_lines.length==3)
            session.do_record("modified_offer_received")
          else
            session.do_record("modified_offer_not_received")
          end
          logd("Received provisional response ")
          response = session.iresponse
          if (response.rseq )
            logd("Sending prack")
            r = session.create_subsequent_request('PRACK')
            r.sdp.session_lines= {:s=> "bansal",:v=>"12",:t=>"55555555"}
            session.send(r)
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
    set_controller("TestPrackSdp_SipInline::UacPrackSdpController")
  end
  
  
  def test_pracksdp
    self.expected_flow = ["> INVITE","< 100", "< 183", "! modified_offer_received", "> PRACK", "< 200 {2,2}", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE","> 100", "> 183", "< PRACK", "! modified_answer_received", "> 200 {2,2}", "< ACK"]
    
    verify_call_flow(:in)
  end
  
end


