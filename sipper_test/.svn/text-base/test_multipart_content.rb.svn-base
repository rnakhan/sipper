
require 'driven_sip_test_case'

class TestMultipartContent < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestMultipartContent_SipInline
      class UasMultipartController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        def on_invite(session)
          multipart_content  = session.irequest.multipart_content
          if ( multipart_content.get_count == 3 and multipart_content.get_bodypart(0).type == "text/plain" \
                and multipart_content.get_bodypart(1).type == "application/sdp" and multipart_content.get_bodypart(2).type == "application/sdp")
            session.do_record("valid_content")
          else  
            session.do_record("invalid_content")
          end
          
          session.respond_with(180)
          r = session.create_response(200)
          sdp = SDP::SdpParser.parse(multipart_content.get_bodypart(1).contents)
          r.sdp = sdp
          session.send(r)
        end
        
        def on_ack(session)
          session.request_with('BYE')
        end
        
        def on_success_res_for_bye(session)        
          session.invalidate(true)
          session.flow_completed_for("TestMultipartContent")  
        end
        
        def order
          0
        end
      end
      
      class UacMultipartController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
                
        def start
          session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
         
          r = session.create_initial_request("INVITE", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          
          part1  = Multipart::MimeBodypart.new("hello", "text/plain")
          part2 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          part3 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          
          multipart_content = Multipart::MimeMultipart.new([part1,part2])
          multipart_content.add_bodypart(part3)
          
          r.multipart_content = multipart_content
          session.send(r)
          logd("Sent a new INVITE from #{name}")
        end

        def on_success_res_for_invite(session)
          if session.iresponse.sdp
            session.do_record("sdp")
          else
            session.do_record("no_sdp")
          end  
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
    set_controller("TestMultipartContent_SipInline::UacMultipartController")
  end
  
  
  def test_sdpbody
    self.expected_flow = ["> INVITE", "< 180", "< 200","! sdp",  "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "! valid_content", "> 180", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
end


