
require 'driven_sip_test_case'


#
class TestMethodSpecificResponseHandling < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasMsrController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
        end
        
       
        
         def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacMsrController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res_for_invite(session)
          session.request_with('ACK')
          session.request_with('BYE')
        end
        
         def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestMethodSpecificResponseHandling")
        end
       
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacMsrController")
  end
  
  
  def test_smoke_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "> BYE", "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "< BYE", "> 200"]
    verify_call_flow(:in)
  end

end


