
require 'driven_sip_test_case'

class TestAckToFailureResponse < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasFaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.respond_with(404)
          logd("Received INVITE sent a 200 from "+name)
          #session.invalidate(true)
        end
             
       
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestAckToFailureResponse")
        end
        
        def order
          0
        end
        
      end
      
      class UacFaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_failure_res(session)
          session.invalidate(true)
          #session.flow_completed_for("TestAckToFailureResponse")
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacFaController")
  end
  
  
  def test_atf_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 404", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 404", "< ACK"]
    verify_call_flow(:in)
  end

  
end
