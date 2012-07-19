

require 'driven_sip_test_case'

class TestRegisterationClearing < DrivenSipTestCase

  def setup
    SipperConfigurator[:ProtocolCompliance] = 'strict'
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasRegistrar2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_register(session)
          logd("Received REGISTER in "+name)
          if session.irequest.contact == "*"
            r = session.create_response(200, "OK")
            r.contact = nil
            session.send(r)
            session.invalidate(true)
          else
            r = session.create_response(200, "OK") 
            registration_store.put(:test, session.irequest.contact.uri.to_s)   
            session.send(r)
          end
          
        end
        
        
        def order
          0
        end
      end
      
      class UacRegister2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          r = Request.create_initial("register", "sip:sipper.com", 
               :from=>"sip:bob@sipper.com", :to=>"sip:bob@sipper.com",
               :contact=>"sip:bob@192.168.1.2",
               :p_session_record=>"msg-info")    
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new REGISTER from "+name)
        end
     
        def on_success_res(session)
           logd("Received response in "+name)
          if session[:regsent]
            if session.iresponse.contact
              session.do_record('contact_found')
            else
              session.do_record('no_contact_found')
            end
            session.invalidate(true)
            session.flow_completed_for("TestRegisterationClearing")
          else
            session[:regsent] = true
            if session.iresponse.contact
              session.do_record('contact_found')
            else
              session.do_record('no_contact_found')
            end
            r = session.create_subsequent_request('REGISTER')
            r.expires = "0"
            r.contact = "*"
            session.send r
          end      
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacRegister2Controller")
  end
  
  
  def test_registration
    self.expected_flow = ["> REGISTER", "< 200", "! contact_found", "> REGISTER", "< 200", "! no_contact_found" ]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< REGISTER", "> 200", "< REGISTER", "> 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::Locator[:RegistrationStore].destroy
    super
  end
  
end
