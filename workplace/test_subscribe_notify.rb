$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class TestSubscribeNotify < DrivenSipTestCase

def self.description
    "Callflow is > SUBSCRIBE,< 202 {0,},< NOTIFY,< 202 {0,},> 200,< NOTIFY,> 200
   
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
    
    module TestSubscribeNotify_SipInline
   
      class Uac2xxController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          r = Request.create_initial("subscribe", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
          subscription = u.create_subscription("message_summary", 5)
          u.add_subscription_to_request(r, subscription)
          r.expires = "1"
          u.send(r)
          logd("Sent a new Subscribe from #{name}")
        end
     
        def on_notify(session)
          logd("Received notify in #{name}")

          subscription = session.get_subscription(session.irequest)

          if subscription == nil
             logd("Unsolicited notify received.")
             session.respond_with(200)
             return
          end

          session.respond_with(200)

          subscription = session.update_subscription(session.irequest)

          if subscription.state == "terminated"
             session.invalidate(true)
             session.flow_completed_for("TestSubscribeNotify")
          end
        end

        def on_subscription_refresh_timeout(session, subscription)
          logd("Received refresh timeout. in #{name}")
        end

        def on_success_res(session)
          logd("Received response in #{name}")
        end
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestSubscribeNotify_SipInline::Uac2xxController")
  end
  
  
  def test_subscribe_notify
    self.expected_flow = ["> SUBSCRIBE","< 202 {0,}", "< NOTIFY", "< 202 {0,}", "> 200", "< NOTIFY", "> 200"]
    start_controller
    verify_call_flow(:out)
  end
  
end


