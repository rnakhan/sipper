require 'driven_sip_test_case'

class TestControllerUsingIctWithNonSuccess < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    
    module SipInline
    
      class UasIctControllerFailure < SIP::SipTestDriverController
      
        def on_invite(session)
          logd("Received INVITE in "+name)
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          r = session.create_response(404, "Not Found")
          session.send(r)
        end
        
        def on_ack(session)
          logd("Received ACK in "+name)
          session.invalidate
          session.flow_completed_for("TestControllerUsingIctWithNonSuccess")
        end
        
        def order
          0
        end
      end
      
      class UacIctControllerFailure < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_ict=>true
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_failure_res(session)
          logd("Received response in "+name)
          begin
            session.create_and_send_ack
          rescue RuntimeError
            session.do_record("Exception in sending ACK to non 2xx from controller")
          end
          session.invalidate
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacIctControllerFailure")
  end
  
  
  def test_ict_controllers
    orig = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance] = 'strict'
    self.expected_flow = ["> INVITE", "< 404", "> ACK", "! Exception_in_sending_ACK_to_non_2xx_from_controller"]  # as ACK is sent by Txn
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 404", "< ACK"] 
    verify_call_flow(:in)
    SipperConfigurator[:ProtocolCompliance] = orig
  end
  
end