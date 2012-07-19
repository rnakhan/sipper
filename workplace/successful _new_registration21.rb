$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class SuccessfulNewRegistration21 < DrivenSipTestCase 

  def setup
    super
    SipperConfigurator[:SessionRecord]='msg-info'
    SipperConfigurator[:WaitSecondsForTestCompletion] = 180
    str = <<-EOF
# FLOW : > REGISTER, < 401, > REGISTER, < 200
#
require 'base_controller'

class SuccessfulNewRegistration21Controller < SIP::SipTestDriverController 

  transaction_usage :use_transactions=>false

  def initialize
    logd('Controller created')
  end

  def start
    r = Request.create_initial("REGISTER", "sip:" + SipperConfigurator[:RegistrarIP],
               :from=>"sip:bob@sipper.com", :to=>"sip:bob@sipper.com",
               :contact=>"sip:bob@"+ SipperConfigurator[:LocalSipperIP] +";" ,
               :expires=>"300",
               :cseq=>"1 REGISTER",
               :p_session_record=>"msg-info")
    r.contact.q="0.9"       
    u = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
    u.send(r)
    logd("Sent a new REGISTER from #{name}")
  end

  def on_success_res(session)
    session.invalidate
    session.flow_completed_for('SuccessfulNewRegistration21')
  end

  def on_failure_res(session)
    if session.iresponse.code == 401
     r = session.create_request_with_response_to_challenge(session.iresponse.www_authenticate, false,"sipper_user", "sipper_passwd")
    end
     session.send r
  end

end
    EOF
    define_controller_from(str)
    set_controller('SuccessfulNewRegistration21Controller')
  end
  
def self.description
     "  
   1. IUT is a Registrar (UAS).

   2.config file should contain the variable :RegistrarIP

   3. Sipper is a User Agent client (UAC).

   4. The variables :LocalSipperIP, :LocalSipperPort may be present in config file, if not then the values must be provided through command line
   e.g 

    srun -i 10.32.4.95 -p 5066 -r <IUT-IP> -o <IUT-PORT> -t test.rb
            \           / 
             \         /
              \       / 
              IP & PORT on which Sipper is running
              
   5. The variables :DefaultRIP, :DefaultRP may be present in config file, if not then the values must be provided through command line
   e.g 

    srun -i <Sipper-IP> -p <Sipper-PORT> -r 10.32.4.83 -o 5062 -t test.rb
                                             \         /
                                              \       /
                                               \     /
                                              IP & PORT on which IUT is running

   6. Test cases having digest authentication, have the username as 'sipper_user' & password as 'sipper_passwd', so Proxy or registrar must be configured using the same username & password. 

   7. Brekeke OnDO SIP Server (Version 1.5.2.0) was used as Proxy or Registrar during test library development."
 end
 
  def test_case_1
    self.expected_flow = ['> REGISTER','< 100 {0,}','< 401','> REGISTER','< 100 {0,}','< 200']
    start_controller
    verify_call_flow(:out)
  end
end
