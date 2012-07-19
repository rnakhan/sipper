
require 'driven_sip_test_case'

class TestSdpBody < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestSdpBody_SipInline
      class UasSdpBodyController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        def on_invite(session)
          if !session['invite']
            if (session.irequest.sdp.session_lines[:t]=="55555555" and session.irequest.sdp.session_lines[:s]=="nasir" \
            and session.irequest.sdp.session_lines[:v]=="5" and session.irequest.sdp.get_owner_version.to_s=="1236599999" and session.irequest.sdp.media_lines.length==3)
              session.do_record("modified_offer_received")
            else
              session.do_record("modified_offer_not_received")
            end
            session.respond_with(180)
            r = session.create_response(200)
            r.sdp.session_lines= {:s=> "nishant",:v=>"12",:t=>"11111111"}
            r.sdp.set_owner_version("1236588888")
            session.send(r)
            session['invite'] =1
          elsif session['invite'] ==1
             if (session.irequest.sdp.session_lines[:s]=="sharat" and session.irequest.sdp.session_lines[:v]=="555")
              session.do_record("new_offer_received")
            else
              session.do_record("new_offer_not_received")
            end 
            session.respond_with(200)
          end  
        end
        
        def on_ack(session)
          if !session['ack']
            session['ack']=1
          elsif session['ack'] ==1  
            session.request_with('BYE')
          end
        end
        
        def on_success_res_for_bye(session)        
          session.invalidate(true)
          session.flow_completed_for("TestSdpBody")  
        end
        
        def order
          0
        end
      end
      
      class UacSdpBodyController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
                
        def start
          session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          session.make_new_offer
          r = session.create_initial_request("INVITE", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          
          # adding two new media lines with attributes
          r.sdp.add_media_lines({:m=>"audio 16000 RTP/AVP 0"})
          r.sdp.add_media_attribute_at(1,"sendonly")
          r.sdp.add_media_attribute_at(1,"rtpmap:0 PCMU/8000")
          r.sdp.add_media_lines({:m=>"video 16000 RTP/AVP 0"})
          r.sdp.add_media_attribute_at(2,"sendrecv")
          r.sdp.add_media_attribute_at(2,"rtpmap:101 telephone-event/8000")
        
          #modifying session lines       
          r.sdp.session_lines= {:s=> "nasir",:v=>"5",:t=>"55555555"}
          
          #modifying version
          r.sdp.set_owner_version("1236599999")          
          session.send(r)
          logd("Sent a new INVITE from #{name}")
        end

        def on_success_res_for_invite(session)
          if !session['2xx']
            if (session.iresponse.sdp.session_lines[:t]=="11111111" and session.iresponse.sdp.session_lines[:s]=="nishant" \
            and session.iresponse.sdp.session_lines[:v]=="12" and session.iresponse.sdp.get_owner_version.to_s=="1236588888")
              session.do_record("modified_answer_received")
            else
              session.do_record("modified_answer_not_received")
            end
            session.request_with('ACK')
            session.offer_answer.make_new_offer
            r = session.create_subsequent_request("INVITE")
            r.sdp.session_lines= {:s=> "sharat",:v=>"555"}
            session.send(r)
            session['2xx']=1
          elsif session['2xx'] ==1
            session.request_with('ACK')
          end          
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
                
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestSdpBody_SipInline::UacSdpBodyController")
  end
  
  
  def test_sdpbody
    self.expected_flow = ["> INVITE", "< 180", "< 200", "! modified_answer_received", "> ACK", "> INVITE", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE",  "! modified_offer_received", "> 180", "> 200", "< ACK", "< INVITE", "! new_offer_received", "> 200",  "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
end


