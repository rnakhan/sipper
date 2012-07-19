
require 'driven_sip_test_case'

# 
# A very simple inlined smoke test.
#
class TestMultiHomed2 < DrivenSipTestCase

  def setup
    @tp = SipperConfigurator[:LocalTestPort]
    @lip = SipperConfigurator[:LocalSipperIP]
    SipperConfigurator[:LocalSipperIP] = ["127.0.0.1", "127.0.0.1"]
    SipperConfigurator[:LocalTestPort] = [5066, 5067]
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestMultiHomed2") if session.iresponse.p_sipper_session == "p2"
        end
        
        def order
          0
        end
        
      end
      
     
      class UacMh2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def specified_transport
          [@lp, @p]
        end
        
        def start
          @lp = SipperConfigurator[:LocalSipperIP][0]
          @p = SipperConfigurator[:LocalTestPort][0]
          u = create_udp_session(@lp, SipperConfigurator[:LocalTestPort][0] )
          u.name = "p1"
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          sleep 1

          @lp = SipperConfigurator[:LocalSipperIP][1]
          @p = SipperConfigurator[:LocalTestPort][1]
          u = create_udp_session(@lp, SipperConfigurator[:LocalTestPort][0])
          u.name = "p2"
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          logd("Sent 2 new INVITEs from "+name)
          
        end
     
        
        def on_success_res(session)
          session.do_record(session.transport.port)
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
    set_controller("SipInline::UacMh2Controller")
  end
  
  
  def test_mh1_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! 5066", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out, 0)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 0)
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! 5067", "> ACK", "< BYE", "> 200"]
    verify_call_flow(:out, 1)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 1)
  end

  def teardown
    SipperConfigurator[:LocalTestPort] = @tp
    SipperConfigurator[:LocalSipperIP] = @lip
    super
  end
  
end
