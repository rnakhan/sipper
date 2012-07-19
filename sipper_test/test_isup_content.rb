#               UAC                      UAS          
#                 |                       | 
#                 |-----INVITE----------->|  (IAM)
#                 |                       | 
#                 |<--------100Trying-----| 
#                 |                       |
#                 |<------180Ringing----- |  (ACM)
#                 |                       |
#                 |<--------200OK---------|  (ANM) 
#                 |                       | 
#                 |-----ACK-------------->| 
#                 |                       |
#                 |-----BYE-------------->|  (REL) 
#                 |                       |
#                 |<--------200OK---------|  (RLC) 
require 'driven_sip_test_case'

class TestIsupContent < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestIsupContent_SipInline
      class UasIsupController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        def on_invite(session)
          multipart_content  = session.irequest.multipart_content
          
          iam_msg = ISUP::IsupParser.parse(multipart_content.get_bodypart(1).contents)      # Get IAM msg object, and then access & verify the fields
          
          if ( multipart_content.get_count == 2 and multipart_content.get_bodypart(1).type == "application/ISUP" and iam_msg.natConInd == "02" and iam_msg.fwdCallInd == "1212" and iam_msg.callingPartyCat == "01") 
            session.do_record("valid_content")
          else  
            session.do_record("invalid_content")
          end
          
          r1 = session.create_response(180)
          part1 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          
          part2  = Multipart::MimeBodypart.new("06 00 00 00", "application/ISUP")     # Creation of ACM msg by passing the hex dump
          
          multipart_content = Multipart::MimeMultipart.new([part1,part2])
          r1.multipart_content = multipart_content
          session.send(r1)
          r2 = session.create_response(200)
          part1 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          
          anm_msg = ISUP::ANM.new          # Creation of ANM msg having the defaut value
          part2  = Multipart::MimeBodypart.new(anm_msg.contents, "application/ISUP")
          multipart_content = Multipart::MimeMultipart.new([part1,part2])
          r2.multipart_content = multipart_content
          session.send(r2)
        end
        
        def on_ack(session)
          r = session.create_subsequent_request('BYE')
          part1 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          part2  = Multipart::MimeBodypart.new("0C 02 00 03 80 81 80", "application/ISUP")
          multipart_content = Multipart::MimeMultipart.new([part1,part2])
          r.multipart_content = multipart_content
          session.send(r)
        end
        
        def on_success_res_for_bye(session)        
          session.invalidate(true)
          session.flow_completed_for("TestIsupContent")  
        end
        
        def order
          0
        end
      end
      
      class UacIsupController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
                
        def start
          session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
         
          r = session.create_initial_request("INVITE", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          
          part1 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          
          iam_msg= ISUP::IAM.new        # Creation of IAM msg having default value 
          iam_msg.natConInd = "02"        # Also can modify the specific fields
          iam_msg.fwdCallInd = "1212"
          iam_msg.callingPartyCat = "01"
          
          part2  = Multipart::MimeBodypart.new(iam_msg.contents,"application/ISUP")
          
          multipart_content = Multipart::MimeMultipart.new([part1,part2])
                 
          r.multipart_content = multipart_content
          session.send(r)
          logd("Sent a new INVITE from #{name}")
        end

        def on_success_res_for_invite(session)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          r = session.create_response(200)
          part1 = Multipart::MimeBodypart.new(SDP::SdpGenerator.make_no_media_sdp, "application/sdp")
          part2  = Multipart::MimeBodypart.new("10 00", "application/ISUP")
          multipart_content = Multipart::MimeMultipart.new([part1,part2])
          r.multipart_content = multipart_content
          session.send(r)
          session.invalidate(true)
        end
                
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestIsupContent_SipInline::UacIsupController")
  end
  
  
  def test_sdpbody
    self.expected_flow = ["> INVITE", "< 180", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "! valid_content", "> 180", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
end


