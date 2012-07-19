
require 'driven_sip_test_case'

# Here UAC sends dtmf sequences on voice detectionand UAS receives dtmf sequences

class Test5Mediadtmf < DrivenSipTestCase

  def setup
    SipperConfigurator[:SipperMediaProcessReuse] = true
    SipperConfigurator[:SipperMedia] = true
    
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class Uas5MediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.set_dtmf_collect_spec("#")
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end

        
       
        def on_media_collected_digits(session, timeoutflag)
          collected_digits = session. dtmf_collected_digits
          if collected_digits.to_i==345
            session.do_record("valid_dtmf_received")
          else
            session.do_record("invalid_dtmf_received")
          end
          session.request_with("bye")
        end
        
        def on_media_dtmf_received(session)
          num = session.imedia_event.dtmf
          puts "!!!!!!!!!!!!!!!!!!!!! " + num.to_s
        end 
        
        
        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("Test5Mediadtmf")
        end
        
        
        def order
          0
        end
        
      end
      
      class Uac5MediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.make_new_offer
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res_for_invite(session)     
          session.request_with('ACK')
        end 
      
        def on_media_connected(session)    
          unless session[:dtmf_sent]
            session.set_media_attributes(:dtmf_spec => "3,sleep 1,4,sleep 1, 5,sleep 1, #")
            session[:dtmf_sent] = true
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
    set_controller("SipInline::Uac5MediaController")
  end
  
  
  def test_media_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "! valid_dtmf_received", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:SipperMediaProcessReuse] = false
    SipperConfigurator[:SipperMedia] = false
    super
  end
  
end
