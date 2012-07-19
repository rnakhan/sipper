
require 'driven_sip_test_case'


class TestLowerCseq < DrivenSipTestCase

  def setup
    @orig_compliance = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance]='strict'
    super
    str = <<-EOF
   
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasLowerCseqController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        session_timer #{@grty*5}
        
        def on_invite(session)
          session.respond_with(200)
        end
        
        def on_ack(session)
          session.invalidate
          session.flow_completed_for("TestLowerCseq")
        end
        
        def order
          0
        end
      end
      
      class UacLowerCseqController < SIP::SipTestDriverController

        transaction_usage :use_transactions=>false

        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          session.request_with('ack') 
          logd("sent ACK now creating an INVITE")
          r = session.create_subsequent_request("invite")
          r.cseq = "1 INVITE" 
          session.send(r)      
        end
        
        def on_failure_res(session)
          session.request_with("ack")
          session.invalidate(true)
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacLowerCseqController")
  end
  
  
  def test_reinvite
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "> INVITE", "< 100","< 500", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "< INVITE", "> 100","> 500", "< ACK"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @orig_compliance
    super
  end
  
end
