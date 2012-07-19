require 'driven_sip_test_case'

class TestRemoteController < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipRemote
      class UacMsgController < SIP::SipTestDriverController
        def start
          r = Request.create_initial("message", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session("192.168.1.3", 5060)
          #todo this MUST be fixed, this coudl easily be forgotten 
          u.record_io = yield  if block_given?
          u.send(r)
          logd("Sent a new request from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.send(session.create_subsequent_request("cleanup"))
          session.invalidate
        end
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipRemote::UacMsgController")
  end
  
  def test_remote_controllers_with_stringio
    self.expected_flow = ["> MESSAGE", "< 200", "> CLEANUP"]
    start_controller(true)
    verify_call_flow(:out)
  end
  
end

