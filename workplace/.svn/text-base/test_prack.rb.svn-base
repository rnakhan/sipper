$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class TestPrack < DrivenSipTestCase

  def self.description
    "Callflow is > INVITE,< 100,< 183,> PRACK,< 200,< 180,> PRACK,< 200 {2,2},> ACK
   
   1. IUT is a User Agent server (UAS).

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

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestPrack_SipInline
    
      class Uac2xxController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
        end
     
        def on_provisional_res(session)
          logd("Received provisional response ")
           response = session.iresponse
           if (response.rseq )
              logd("Sending prack")
              session.create_and_send_prack
           end
        end

        def on_success_res(session)
          logd("Received response in #{name}")
          response = session.iresponse

          if session.iresponse.get_request_method == 'PRACK'
             logd("Received prack response")
          else
            session.create_and_send_ack 
            session.invalidate(true)
            session.flow_completed_for("TestPrack")
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestPrack_SipInline::Uac2xxController")
  end
  
  
  def test_prack
    self.expected_flow = ["> INVITE","< 100", "< 183", "> PRACK", "< 200", "< 180", "> PRACK", "< 200 {2,2}", "> ACK"]
    start_controller
    verify_call_flow(:out)
  end
  
end


