
require 'driven_sip_test_case'

class TestValidations < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasValidationsController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          logd("Received INVITE in "+name)
          r = session.create_response(200, "OK") 
          r.test_header = "hello"
          r.test_header.mytag = "123"
          session.send(r)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestValidations")
        end
        
        def order
          0
        end
      end
      
      class UacValidationsController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.validate_presence_of_headers :test_header
          session.validate_presence_of_header_params :test_header, :mytag
          session.validate_header_values :test_header=>'hello;mytag=123'
          session.request_with('ack')
          session.invalidate(true)
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacValidationsController")
  end
  
  
  def test_header_params
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! true {3,3}", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK"]
    verify_call_flow(:in)
  end
  
end
