
require 'driven_sip_test_case'


class TestReInviteWithOngoingIst < DrivenSipTestCase

  def setup
    @orig_compliance = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance]='strict'
    super
    str = <<-EOF
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasReInvite3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        t2xx_usage true
        
        def on_invite(session)
          session.request_with("invite")
        rescue RuntimeError
          session.do_record("existing_ist")
          session.respond_with(200)
        end
        
        def on_ack(session)
          r = session.request_with("invite")  
        end
        
        def on_success_res(session)
          session.request_with("ack")
          session.invalidate(true)
        end
        
        
        def order
          0
        end
      end
      
      class UacReInvite3Controller < SIP::SipTestDriverController

        transaction_usage :use_transactions=>true
        t2xx_usage true
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)  
          session.request_with('ack') 
        end
        
        def on_invite(session)
          session.respond_with(200)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestReInviteWithOngoingIst")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacReInvite3Controller")
  end
  
  
  def test_reinvite
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< INVITE", "> 100", "> 200", "< ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! existing_ist", "> 200", "< ACK", "> INVITE", "< 100", "< 200", "> ACK"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @orig_compliance
    super
  end
  
end
