$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class SuccessfulSessionEstablishment31 < DrivenSipTestCase 

  def setup
    super
    SipperConfigurator[:SessionRecord]='msg-info'
    SipperConfigurator[:WaitSecondsForTestCompletion] = 180
    str = <<-EOF
# FLOW :  > INVITE, < 180, < 200, > ACK, < BYE, > 200
#
require 'base_controller'

class SuccessfulSessionEstablishment31Controller < SIP::SipTestDriverController 

 transaction_usage :use_transactions=>false

  def initialize
    logd('Controller created')
  end

  def on_success_res_for_bye(session)
    session.invalidate(true)
    session.flow_completed_for('SuccessfulSessionEstablishment31')
  end

  def on_provisional_res(session)
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
    #Creating the URI.1234 is the called party number.
    my_uri= "sip:1234@" + SipperConfigurator[:LocalSipperIP]
    r = session.create_initial_request("invite", my_uri)
    r.to = my_uri
    session.send(r)
  end

  def on_success_res_for_invite(session)
    session.request_with('ACK')
    session.request_with('BYE')
  end

end
    EOF
    define_controller_from(str)
    set_controller('SuccessfulSessionEstablishment31Controller')
  end

  def self.description
     "Ensure that the IUT on receipt of an INVITE request, sends a Success (200 OK) or a provisional(101-199) response.
       
    1. IUT is a User Agent server (UAS). Xlite software (version 3.0 build 29712) is used as UAS during test library development. 

    2. Sipper is a User Agent client (UAC).

    3. The variables :LocalSipperIP, :LocalSipperPort may be present in config file, if not then the values must be provided through command line
    e.g 

    srun -i 10.32.4.95 -p 5066 -r <IUT-IP> -o <IUT-PORT> -t test.rb
              \           / 
               \         /
                \       / 
                IP & PORT on which Sipper is running
              
    4. The variables :DefaultRIP, :DefaultRP may be present in config file, if not then the values must be provided through command line
    e.g 

    srun -i <Sipper-IP> -p <Sipper-PORT> -r 10.32.4.83 -o 5062 -t test.rb
                                             \         /
                                              \       /
                                               \     /
                                              IP & PORT on which IUT is running"
  end

  def test_case_1
    self.expected_flow = ['> INVITE','< 180','< 200','> ACK','> BYE','< 200']
    start_controller
    verify_call_flow(:out)
  end
end
