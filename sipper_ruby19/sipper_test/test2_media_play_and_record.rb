
require 'driven_sip_test_case'

# Here the offer is made by the UAC
class Test2MediaPlayAndRecord < DrivenSipTestCase

  def setup
    SipperConfigurator[:SipperMediaProcessReuse] = true
    SipperConfigurator[:SipperMedia] = true
    
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class Uas2MediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
                                            
          if File.exists?("rec.au")
            session.do_record("rec.au_found")
          else
            session.do_record("rec.au_not_present")
          end
          
          session.set_media_attributes(:rec_spec=>'rec.au', :play_spec=>'') 
          
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        # why this goes into a loop and does not record proper media
        #def on_media_voice_activity_detected(session)
        #  session.update_audio_spec(:play_spec=>'',:rec_spec=>'rec.au')                                   
        #end
        
        
        def on_media_voice_activity_stopped(session)
          session.request_with("bye")
        end

        def on_ack(session)
          #session.set_media_attributes(:play_spec=>'',:rec_spec=>'rec.au')
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("Test2MediaPlayAndRecord")
        end
        
        def order
          0
        end
        
      end
      
      class Uac2MediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.make_new_offer
          u.set_media_attributes(:play_spec =>'PLAY hello_sipper.au')
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
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
    set_controller("SipInline::Uac2MediaController")
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
