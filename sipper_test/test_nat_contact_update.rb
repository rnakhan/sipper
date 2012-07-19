
require 'driven_sip_test_case'


class TestNatContactUpdate < DrivenSipTestCase
  
  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasNatContactController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          if session.irequest.to[:tag]
            session[:initial] = false
          else  
            session[:initial] = true
          end
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          unless session[:initial]
            session.request_with("bye")
          end
        end
        
        def on_success_res(session)
          session.invalidate(true)
          if session[:initial] == false 
            session.flow_completed_for("TestNatContactUpdate")
          end
        end
        
        def order
          0
        end
        
      end
      
      
      
      class UacNatContactController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        behind_nat true
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])     
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")          
          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          r.contact = "<sip:1234@192.168.1.1:2222>"  #bogus contact
          u.send(r)
          u[:request_number] = '1'
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
          if session[:request_number] == '1'
            session[:request_number] = '2'
            session.request_with("INVITE")
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
    set_controller("SipInline::UacNatContactController")
  end
  
  
  def test_nc_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK","> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out, 0)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK","< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 0)
    
  end
  
  
end
