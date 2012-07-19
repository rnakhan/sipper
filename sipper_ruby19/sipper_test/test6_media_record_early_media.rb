
require 'driven_sip_test_case'

# Here UAC records, UAS plays and UAS sends the offer

class Test6MediaRecordEarlyMedia < DrivenSipTestCase

  def setup
    SipperConfigurator[:SipperMediaProcessReuse] = true
    SipperConfigurator[:SipperMedia] = true
    @pc = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance] = 'lax'
    
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class Uas6MediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
                                            
          if File.exists?("rec.au")
            session.do_record("rec.au_found")
          else
            session.do_record("rec.au_not_present")
          end
          
          session.set_media_attributes(:play_spec =>'PLAY hello_sipper.au 5')
          session.respond_with(180)
          logd("Received INVITE sent a 180 from "+name)
          session.schedule_timer_for("487_response", 5000)
        end
        
        def on_timer(session, task)
          session.respond_with(487)
        end
        
        def on_ack(session)
          if File.exists?("rec.au")
            session.do_record("rec.au_found")
          end
          session.invalidate(true)
          session.flow_completed_for("Test6MediaRecordEarlyMedia")
        end   
        
        
        
        def order
          0
        end
        
      end
      
      class Uac6MediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.make_new_offer
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_provisional_res(session)
          session.set_media_attributes(:play_spec=>'',:rec_spec=>'rec.au')
        end

        def on_failure_res(session)
          session.invalidate(true)
        end
           
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::Uac6MediaController")
  end
  
  
  def test_media_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 180", "< 487", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! rec.au_not_present", "> 180", "> 487", "< ACK", "! rec.au_found"]
    verify_call_flow(:in)
  end
  
  
  def teardown
    SipperConfigurator[:SipperMediaProcessReuse] = false
    SipperConfigurator[:SipperMedia] = false
    SipperConfigurator[:ProtocolCompliance] = @pc
    File.delete "rec.au" if File.exists? "rec.au"
    super
  end
 
end
