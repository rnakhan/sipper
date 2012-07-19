
require 'driven_sip_test_case'


class TestMultiHomed1 < DrivenSipTestCase

  def setup
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [5066, 5067]
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasP1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 5066]
        end
        
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
        end
        
        def order
          0
        end
        
      end
      
      class UasP2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 5067]
        end
        
        def on_invite(session)
          session.name = "p2controller"
          session.do_record(session.transport.port)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestMultiHomed1")
        end
        
        def order
          0
        end
        
      end
      
      class UacMh1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], 5066)
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          sleep 1
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], 5067)
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          logd("Sent 2 new INVITEs from "+name)
          
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
    set_controller("SipInline::UacMh1Controller")
  end
  
  
  def test_mh1_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! p1controller", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out, 0)
    self.expected_flow = ["< INVITE", "> 100", "! 5066", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 0)
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! p2controller", "> ACK", "< BYE", "> 200"]
    verify_call_flow(:out, 1)
    self.expected_flow = ["< INVITE", "> 100", "! 5067", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 1)
  end

  def teardown
    SipperConfigurator[:LocalTestPort] = @tp
    super
  end
  
end
