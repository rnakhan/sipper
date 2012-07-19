
require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#

require 'transport/base_transport'
require 'rexml/document'

class TestXmlBody < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasXmlController < SIP::SipTestDriverController
       include REXML
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          xml_data = session.irequest.body
          doc = REXML::Document.new(xml_data)
          audio_urls = []
          doc.elements.each('MediaServerControl/request/play/prompt/audio') do |e|
            audio_urls << e.attributes.get_attribute('url').value    
          end
          if audio_urls[0] == 'http://prompts.example.net/en_US/welcome.au'
            session.do_record('parsed_mscml')
          end
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestXmlBody")
        end
        
        def order
          0
        end
        
      end
      
      class UacXmlController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          body_str = <<-BODYMARKER
          <?xml version="1.0" encoding="utf-8"?>
  <MediaServerControl version="1.0">
    <request>
      <play>
        <prompt>
          <audio url="http://prompts.example.net/en_US/welcome.au"/>
        </prompt>
      </play>
    </request>
  </MediaServerControl>
          BODYMARKER
          r.content = body_str
          r.content_type = "application/mediaservercontrol+xml"
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
    set_controller("SipInline::UacXmlController")
  end
  
  
  def test_xml_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! parsed_mscml", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end
