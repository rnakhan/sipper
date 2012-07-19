require 'driven_sip_test_case'

class TestInDialogRequest < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInDialog
      class UasInviteController < SIP::SipTestDriverController
        def on_invite(session)
          logd("Received INVITE in "+name)
          session.local_tag = 5  #todo differentiate automatically on the same container somehow
          r = session.create_response(200, "OK")
          session.send(r)
        end
        
        def on_ack(session)
          logd("Received ACK in "+name)
          session.invalidate
          session.flow_completed_for("TestInDialogRequest") 
        end
        
        def order
          0
        end
      end
      
      class UacInviteController < SIP::SipTestDriverController
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          #todo this MUST be fixed, this coudl easily be forgotten 
          u.record_io = yield  if block_given?
          u.send(r)
          logd("Sent a new request from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.send(session.create_subsequent_request("ack"))
          session.invalidate
        end
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInDialog::UacInviteController")
  end
  
  
  def test_indialog_controllers
    self.expected_flow = ["> INVITE", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 200", "< ACK"]
    verify_call_flow(:in)
  end
  
end
  
