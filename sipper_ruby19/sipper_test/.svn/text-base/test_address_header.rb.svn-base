require 'driven_sip_test_case'

class TestAddressHeader < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasAddressHeaderController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          logd("Received INVITE in "+name)
          r = session.create_response(200, "OK") 
          r.to.tag = "abc"   
          session.send(r)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestAddressHeader")
        end
        
        def order
          0
        end
      end
      
      class UacAddressHeaderController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          r = Request.create_initial("invite", "<sip:nasir@sipper.com>;myparam=value", 
                :p_session_record=>"msg-info", :from=>"Nasir Khan <sip:nasir@sipper.com>;myparam=value;tag=xyz")                    
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.request_with('ack')
          session.invalidate(true)
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacAddressHeaderController")
  end
  
  
  def test_address_headers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK"]
    verify_call_flow(:in)
  end
  
end

