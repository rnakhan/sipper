
require 'driven_sip_test_case'


class TestMultipleContacts < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasMcController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.do_record(session.irequest.contacts[0])
          session.do_record(session.irequest.contacts[1])
          r = session.create_response(200)
          r.contact = "sip:xyz@sipper.com"
          r.contact.expires='500'
          r.add_contact("mailto:xyz@sipper.com")
          r.contacts[1].expires='400'
          session.send r
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestMultipleContacts")
        end
        
        def order
          0
        end
        
      end
      
      class UacMcController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.contact = "sip:abc@sipper.com"
          r.contact.expires="500"
          r.add_contact("<mailto:abc@sipper.com>;expires=400")

          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.do_record(session.iresponse.contacts[0])
          session.do_record(session.iresponse.contacts[1])
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
  end
  
  
  def test_smoke_controllers
    start_named_controller("SipInline::UacMcController")
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! <sip:xyz@sipper.com>;expires=500","! <mailto:xyz@sipper.com>;expires=400",  "> ACK", "< BYE", "> 200"]
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! <sip:abc@sipper.com>;expires=500","! <mailto:abc@sipper.com>;expires=400", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end
