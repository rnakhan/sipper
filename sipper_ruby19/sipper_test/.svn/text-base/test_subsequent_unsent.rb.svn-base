
require 'driven_sip_test_case'

class TestSubsequentUnsent < DrivenSipTestCase

  def setup
    @orig_compliance = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance]='strict'
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasUnsentController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
     
        def on_invite(session)
          session.respond_with(200)
        end
        
        def on_ack(session)
          r1 = session.create_subsequent_request("message")
          r2 = session.create_subsequent_request("message")
          session.send r2
        rescue RuntimeError
          session.do_record("cannot_send_message")
          session.rollback_to_unsent_state
          session.request_with("message")
        end
        
        def on_success_res(session)
          res = session.iresponse 
          if res.get_request_method == "MESSAGE" &&
             SipperUtil.cseq_number(res.cseq) == 1
             session.invalidate(true)
             session.flow_completed_for("TestSubsequentUnsent")
          end
        end
        
        def order
          0
        end
      end
      
      class UacUnsentController < SIP::SipTestDriverController

        transaction_usage :use_transactions=>true

        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          session.request_with('ack')   
        end
        
        def on_message(session)
          session.respond_with(200)
          session.invalidate(true)
        end 
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacUnsentController")
  end
  
  
  def test_subsequent
    self.expected_flow = ["> INVITE", "< 100", "< 200 {1,}", "> ACK", "< MESSAGE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE {1,}", "> 100", "> 200", "< ACK", "! cannot_send_message", "> MESSAGE", "< 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @orig_compliance
    super
  end
  
end

