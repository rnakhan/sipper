
require 'driven_sip_test_case'

# A UAS that receives a second INVITE before it sends the final response to a first 
# INVITE with a lower CSeq sequence number on the same dialog MUST return a 500 
# (Server Internal Error) response to the second INVITE and MUST include a Retry-After 
# header field with a randomly chosen value of between 0 and 10 seconds.

class TestReInviteUasOngoingIst < DrivenSipTestCase

  def setup
    @orig_compliance = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance]='strict'
    super
    str = <<-EOF
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasReInvite4Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        session_timer #{@grty*6}
        
        def on_invite(session)
          session.invalidate
        end
        
        
        def order
          0
        end
      end
      
      class UacReInvite4Controller < SIP::SipTestDriverController

        transaction_usage :use_transactions=>true
        session_timer #{@grty*8}
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_trying_res(session)
          unless session['re-invite-sent']
            orig_compliance = SipperConfigurator[:ProtocolCompliance]
            SipperConfigurator[:ProtocolCompliance] = 'lax'
            session.request_with("invite")
            SipperConfigurator[:ProtocolCompliance] = orig_compliance
            session['re-invite-sent'] = true
          end
        end
        
        def on_failure_res(session)
          session.do_record("retry_after_found") if session.iresponse.retry_after
          session.invalidate
          session.flow_completed_for("TestReInviteUasOngoingIst")  
        end
     
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacReInvite4Controller")
  end
  
  
  def test_reinvite
    self.expected_flow = ["> INVITE", "< 100", "> INVITE", "< 100", "< 500", "> ACK", "! retry_after_found"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "< INVITE", "> 100", "> 500", "< ACK"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @orig_compliance
    super
  end
  
end