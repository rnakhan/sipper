
require 'driven_sip_test_case'

require 'transport/base_transport'


class TestCustomRecord < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasCrController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        emit_console true
        
        def on_invite(session)
          session.make_new_offer
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("options")
        end
        
        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestCustomRecord")
        end
        
        def on_success_res_for_options(session)
          if rand(10)%2 == 0
            session.request_with("options")
          else
            session.request_with("bye")
          end
        end
        
        def order
          0
        end
        
      end
      
      class UacCrController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.offer_answer.make_new_offer
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_options(session)
          session.respond_with(200)
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacCrController")
  end
  
  
  def test_smoke_controllers
   
    start_controller
    recording = get_in_recording.get_info_only_recording
    assert_equal("< INVITE", recording[0])
    assert_equal("> OPTIONS", recording[-4])
    assert_equal("< 200", recording[-3])
    assert_equal("> BYE", recording[-2])
    assert_equal("< 200", recording[-1])
  end
  
end
