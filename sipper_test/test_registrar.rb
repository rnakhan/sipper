
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
          session.send(r)
          
          if !session[:reg_count]
            session[:reg_count] =1
          else
            session[:reg_count] =session[:reg_count]+ 1
          end
          
          session.invalidate(true) if session[:reg_count] == 3
        end
        
        def order
          0
        end
      end
      
      class UacRegisterController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_register_request("sip:sipper.com", "sip:bob@sipper.com", "sip:abc@abc.com")
          r.p_session_record = "msg-info"
          r.expires = '400'
          r.contact.expires='500'
          r.add_contact('<mailto:abc@sipper.com>')
          r.format_as_separate_headers_for_mv(:contact)  
          u.send(r)
          logd("Sent a new REGISTER from #{name}")
        end
     
        def on_success_res(session)
          if !session['2xx'] 
            session['2xx'] =1
            logd("Received response in #{name}")
            puts session.iresponse.contacts.to_s
            if session.iresponse.contacts.to_s.include?("<sip:abc@abc.com>;expires=500<mailto:abc@sipper.com>;expires=400")
              session.do_record('register_success')
            end
            #add a contact
            r= session.create_subsequent_request("REGISTER")
            r.contact = "sip:sharat@abc.com"
            r.expires = "800"
            session.send r
            
          elsif session['2xx'] == 1
            session['2xx'] = 2
            if session.iresponse.contacts.to_s.include?("<sip:abc@abc.com>;expires=500<mailto:abc@sipper.com>;expires=400<sip:sharat@abc.com>;expires=800")
              session.do_record('contact_added')
            end
            #update a contact
            r= session.create_subsequent_request("REGISTER")
            r.expires = "400"
            r.contact = "sip:abc@abc.com"
            session.send r
          
          elsif   session['2xx'] == 2
            if session.iresponse.contacts.to_s.include?("<sip:abc@abc.com>;expires=400<mailto:abc@sipper.com>;expires=400<sip:sharat@abc.com>;expires=800")
              session.do_record('contact_updated')
            end
            session.invalidate(true)
            session.flow_completed_for("TestRegistrationController")          
          end  
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestRegistrationController_SipInline::UacRegisterController")
  end
  
  
  def test_registration
    self.expected_flow = ["> REGISTER", "< 200","! register_success","> REGISTER", "< 200","! contact_added","> REGISTER", "< 200","! contact_updated"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< REGISTER", "> 200","< REGISTER", "> 200","< REGISTER", "> 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::Locator[:RegistrationStore].destroy
    super
  end
  
end

