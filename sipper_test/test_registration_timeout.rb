require 'driven_sip_test_case'

class TestRegistrationTimeout < DrivenSipTestCase

  def setup
    SipperConfigurator[:ProtocolCompliance] = 'strict'
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module TestRegistrationTimeout_SipInline
      class UasRegistrarController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        def on_register(session)
          logd("Received REGISTER in "+name)
          r = session.create_response(200, "OK")        
          session.send(r) 
          
          if !session[:register]
            session[:register] =1
          elsif session[:register] == 1
            session.invalidate(true)
          end
           
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
               :contact=>"sip:abc@abc.com",
               :expires=>"15",
               :p_session_record=>"msg-info")
          r.contact.expires='15'
          r.add_contact('mailto:abc@sipper.com')
          r.format_as_separate_headers_for_mv(:contact)
          
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new REGISTER from #{name}")
        end
        
        def on_registration_expiry(session, registration)
          logd("Timer received in #{name}")
          #Refresh registration
          r = session.create_subsequent_request('REGISTER')
          session.send r
        end
     
        def on_success_res(session)
          if !session['2xx'] 
            session['2xx'] =1
            logd("Received response in #{name}")
            session.start_registration_expiry_timer
          elsif session['2xx'] == 1
            session.invalidate(true)
            session.flow_completed_for("TestRegistrationTimeout")            
          end
        end       
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestRegistrationTimeout_SipInline::UacRegisterController")
  end
  
  
  def test_registration
    self.expected_flow = ["> REGISTER", "< 200","> REGISTER","< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< REGISTER", "> 200","< REGISTER","> 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::Locator[:RegistrationStore].destroy
    super
  end
  
end
