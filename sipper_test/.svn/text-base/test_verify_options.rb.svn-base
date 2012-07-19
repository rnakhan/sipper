

require 'driven_sip_test_case'
require 'custom_message'

class TestVerifyOptions < DrivenSipTestCase

  def setup
    SipperConfigurator[:ControllerPath] = nil
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestVerifyOptions_SipInline
      class BobLabAndDeskController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
       
        session_timer 1000
        
        def interested?(req)
          !req[:replaces]
        end
        
        def on_invite(bob_session1)
          bob_session1.name = "bob_session1"
          bob_session1.respond_with(180)
          bob_session2 = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          bob_session2.name = "bob_session2"
          r = bob_session2.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.replaces = bob_session1.create_replaces_header
          bob_session2.send(r)
          logd("Sent a new Invite with replaces from " + name)  
        end

      
        def on_success_res(bob_session2)
          logd("Received response in "+name)
          bob_session2.create_and_send_ack
          bob_session2.invalidate(true)
        end

        def on_cancel(bob_session1)
           logd("Received cancel request in #{name}")
           bob_session1.invalidate
        end
      end
   
      
      
      
      class AliceController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true        
        session_timer 2000
        
        
        def interested?(req)
          req[:replaces]
        end
        
        def start
          alice_session1 = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          alice_session1.name = "alice_session1"
          alice_session1.request_with('INVITE', 'sip:nasir@sipper.com', :p_session_record=>"msg-info" )
          logd("Sent a new Invite from " +name)
        end
     
        def on_invite(alice_session2)
          alice_session2.name = "alice_session2"
          if alice_session2.irequest[:replaces] != nil
             alice_session1 = alice_session2.find_session_from_replaces
             alice_session1.post_custom_message(CustomMessage.new)
          end  
          alice_session2.respond_with(200)
        end
        
        def on_custom_msg(alice_session1, msg)
          logd("Received Custom message in "+ name)
          alice_session1.create_and_send_cancel_when_ready
        end
        
        def on_failure_res(alice_session1)
          logd("Received failure response in "+ name)
          alice_session1.invalidate(true)
        end

        def on_ack(alice_session2)
          logd("Received ACK in "+ name)
          alice_session2.invalidate
          alice_session2.flow_completed_for("TestVerifyOptions")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestVerifyOptions_SipInline::AliceController")
  end
  
  
  def test_verify_options
    # alice_session1
    self.expected_flow = ["> INVITE","< 100", "< 180", "> CANCEL", "< 200", "< 487", "> ACK"]
    start_controller
    verify_call_flow()


    # bob_session1
    self.expected_flow = ["< INVITE","> 100", "> 180", "< CANCEL", "> 200", "> 487", "< ACK"]
    verify_call_flow(:in)

    # bob_session2
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK"]
    verify_call_flow(1)

    # alice_session2
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK"]
    verify_call_flow(:in, 1)
  end
  

  
end
