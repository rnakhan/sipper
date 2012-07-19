
require 'driven_sip_test_case'

class TestRegistrationController < DrivenSipTestCase

  def setup
    SipperConfigurator[:ProtocolCompliance] = 'strict'
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module TestRegistrationController_SipInline
      class UasRegistrarController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_register(session)
          logd("Received REGISTER in "+name)
          r = session.create_response(200, "OK") 
          registration_store.put(:test, session.irequest.contact.uri.to_s)   
          session.send(r)
          session.invalidate(true)
        end
        
        
        def order
          0
        end
      end
      
      class UacRegisterController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          r = Request.create_initial("register", "sip:sipper.com", 
               :from=>"sip:bob@sipper.com", :to=>"sip:bob@sipper.com",
               :contact=>"sip:bob@192.168.1.2",
               :p_session_record=>"msg-info")    
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new REGISTER from #{name}")
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          session.do_record(registration_store.get(:test))
          session.invalidate(true)
          session.flow_completed_for("TestRegistrationController")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestRegistrationController_SipInline::UacRegisterController")
  end
  
  
  def test_registration
    self.expected_flow = ["> REGISTER", "< 200", "! sip:bob@192.168.1.2"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< REGISTER", "> 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::Locator[:RegistrationStore].destroy
    super
  end
  
end

