
require 'driven_sip_test_case'


class TestNatConfig < DrivenSipTestCase
  
  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasNatConfigController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session[:test_number] = session.irequest.test_number.to_s
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          if session[:test_number] == '3' 
            session.flow_completed_for("TestNatConfig")
          end
        end
        
        def order
          0
        end
        
      end
      
      class UacNatConfigController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          bh = SipperConfigurator[:BehindNAT]
          SipperConfigurator[:BehindNAT] = true
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u[:bh] = bh
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.test_number = "1"
          u[:test_number] = "1"
          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          if session.iresponse.via[:rport]
            session.do_record("rport_found")  
          else
            session.do_record("rport_not_found")
          end
          session.request_with('ACK')
        end
        
        def on_bye(session)
          session.respond_with(200)
          if session[:test_number] == '1'
            SipperConfigurator[:BehindNAT] = session[:bh] 
            bh = SipperConfigurator[:BehindNAT]
            SipperConfigurator[:BehindNAT] = false
            u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
            u[:bh] = bh
            r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
            r.test_number = "2"
            u[:test_number] = "2"
            r.sdp = SDP::SdpGenerator.make_no_media_sdp
            u.send(r)
            logd("Sent a new INVITE from "+name)
          elsif  session[:test_number] == '2'
            SipperConfigurator[:BehindNAT] = session[:bh] 
            bh = SipperConfigurator[:BehindNAT]
            SipperConfigurator[:BehindNAT] = false
            u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
            u.set_behind_nat(true)
            u[:bh] = bh
            r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
            r.test_number = "3"
            u[:test_number] = "3"
            r.sdp = SDP::SdpGenerator.make_no_media_sdp
            u.send(r)
            logd("Sent a new INVITE from "+name)
          elsif   session[:test_number] == '3'
            SipperConfigurator[:BehindNAT] = session[:bh]
          end  
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacNatConfigController")
  end
  
  
  def test_nc_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! rport_found", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out, 0)
    
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! rport_not_found", "> ACK", "< BYE", "> 200"]
    verify_call_flow(:out, 1)
    
     self.expected_flow = ["> INVITE", "< 100", "< 200", "! rport_found", "> ACK", "< BYE", "> 200"]
    verify_call_flow(:out, 2)
  end
  
  
end
