
require 'driven_sip_test_case'


class TestRport < DrivenSipTestCase

  def setup
    @pc = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance] = 'lax'
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasRp1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        
        def on_invite(session)
          session.name = "p1controller"
          session.do_record(session.transport.port)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestRport")
        end
        
        def order
          0
        end
        
      end
      
  
      class UacRpMh1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], 5066)
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.via.rport = ''
          r.via.sent_by_port = "6066"
          u.send(r)         
        end
     
        
        def on_success_res(session)
          session.do_record(session.iresponse.p_sipper_session.to_s)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacRpMh1Controller")
  end
  
  
  def test_rp_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! p1controller", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out, 0)
    self.expected_flow = ["< INVITE", "> 100", "! 5066", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 0)
  end

  def teardown
    SipperConfigurator[:ProtocolCompliance] = @pc
    super
  end
  
end
