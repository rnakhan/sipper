
require 'driven_sip_test_case'

# A UAS that receives an INVITE on a dialog while an INVITE it had sent on that 
# dialog is in progress MUST return a 491 (Request Pending) response to the received INVITE.

class TestReInviteUasOngoingIct < DrivenSipTestCase

  def setup
    @orig_compliance = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance]='strict'
    super
    str = <<-EOF
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasReInvite5Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          orig_compliance = SipperConfigurator[:ProtocolCompliance]
          SipperConfigurator[:ProtocolCompliance] = 'lax'
          session.request_with("invite")
          SipperConfigurator[:ProtocolCompliance] = orig_compliance
        end
        
        def on_failure_res(session)
          session.respond_with(200)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestReInviteUasOngoingIct")  
        end
     
        
        def order
          0
        end
      end
      
      class UacReInvite5Controller < SIP::SipTestDriverController

        transaction_usage :use_transactions=>true
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end 
        
        def on_success_res(session)
          session.request_with("ack")
          session.invalidate(true)
        end    
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacReInvite5Controller")
  end
  
  
  def test_reinvite
    self.expected_flow = ["> INVITE", "< 100", "< INVITE", "> 100", "> 491", "< ACK", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> INVITE", "< 100", "< 491", "> ACK", "> 200", "< ACK"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @orig_compliance
    super
  end
  
end
