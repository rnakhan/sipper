
require 'driven_sip_test_case'

# Here offer is made by the UAS
class TestMediaPlayAndRecord < DrivenSipTestCase

  def setup
    SipperConfigurator[:SipperMediaProcessReuse] = true
    SipperConfigurator[:SipperMedia] = true
    
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasMediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
                                            
          if File.exists?("rec.au")
            session.do_record("rec.au_found")
          else
            session.do_record("rec.au_not_present")
          end   
          session.offer_answer.make_new_offer
          session.set_media_attributes(:play_spec=>'',:rec_spec=>'rec.au')
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
  

        def on_ack(session)
          #session.set_media_attributes(:play_spec=>'',:rec_spec=>'rec.au')
        end
        
        def on_media_voice_activity_stopped(session)
          session.request_with("bye")
        end
        
        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestMediaPlayAndRecord")
        end
        
        
        
        def order
          0
        end
        
      end
      
      class UacMediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")        
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res_for_invite(session)
          session.set_media_attributes(:play_spec =>'PLAY hello_sipper.au')
          session.request_with('ACK')
        end
       
        def on_bye(session)
          session.respond_with(200)
          if File.exists?("rec.au")
            session.do_record("rec.au_found")
          end
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacMediaController")
  end
  
  
  def test_media_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200", "! rec.au_found"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! rec.au_not_present", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
  
  def teardown
    SipperConfigurator[:SipperMediaProcessReuse] = false
    SipperConfigurator[:SipperMedia] = false
    File.delete "rec.au" if File.exists? "rec.au"
    super
  end
 
end
