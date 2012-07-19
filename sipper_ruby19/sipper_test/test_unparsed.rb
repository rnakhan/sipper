
require 'driven_sip_test_case'


class TestUnparsed < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasUpController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_info(session)
          session.do_record(session.irequest.mytest.to_s)
          session.respond_with(200)
          logd("Received INFO sent a 200 from "+name)
          session.invalidate(true)
        end
        
      
      
        
        def order
          0
        end
        
      end
      
      class UacUpController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("info", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.assign_unparsed(:mytest, "  blah  ")
          m = u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.invalidate(true)   
          session.flow_completed_for("TestUnparsed")
        end
        
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacUpController")
  end
  
  
  def test_up_controllers
    self.expected_flow = ["> INFO",  "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INFO",  "!   blah  ",  "> 200"]
    verify_call_flow(:in)
  end

  
end