require 'driven_sip_test_case'

class TestInlineController < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module TestInlineController_SipInline
      class UasMsgController < SIP::SipTestDriverController
        def on_message(session)
          logd("Received MESSAGE in "+name)
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          r = session.create_response(200, "OK")
          session.send(r)
          session.invalidate
        end
        
        def order
          0
        end
      end
      class UacMsgController < SIP::SipTestDriverController
        def start
          r = Request.create_initial("message", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          #todo this MUST be fixed, this coudl easily be forgotten 
          u.record_io = yield  if block_given?
          u.send(r)
          logd("Sent a new request from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.schedule_timer_for("invalidate_timer", 100) 
        end
        
        def on_timer(session, task)
          logd("Timer invoked in "+name)
          session.invalidate
          session.flow_completed_for("TestInlineController")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestInlineController_SipInline::UacMsgController")
  end
  
  def test_inline_controllers_with_stringio
    self.expected_flow = ["> MESSAGE", "< 200"]
    start_controller(true)
    verify_call_flow(:out)
    self.expected_flow = ["< MESSAGE", "> 200"]
    verify_call_flow(:in)
  end
  
  def test_inline_controllers
    self.expected_flow = ["> MESSAGE", "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< MESSAGE", "> 200"]
    verify_call_flow(:in)
  end
  
end
