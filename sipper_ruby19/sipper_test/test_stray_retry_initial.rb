
# Get a subsequent request and retry it as iniytial. 
# Note the second session that is created is not recorded
# because it does not have the session record header. 
# 
require 'driven_sip_test_case'

class TestStrayRetryInitial < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'stray_message_manager'
    require 'udp_session'
    
    class RetryStrayInitialHandler < SIP::StrayMessageHandler
      def handle(m)
        [SIP::StrayMessageHandler::SMH_TREAT_INITIAL, m]
      end
    end
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasStrayRetryInitialController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
 
        def initialize
          logd(name+' controller created')
        end
      
        def on_invite(session)
          session.respond_with(200)
        end
      
        def on_ack(session)
          session.invalidate(true)
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacStrayRetryInitialController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          if session.iresponse.get_request_method == "INVITE"
            session.request_with("ack")
            bye = session.create_subsequent_request("bye")
            bye.from.tag = "bad_tag"
            session.force_update_session_map = true
            session.send(bye)
          else
            session.invalidate(true)
            session.flow_completed_for("TestStrayRetryInitial")
          end
        end
       
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacStrayRetryInitialController")
  end
  
  
  def test_stray_controller1
    self.expected_flow = ["> INVITE", "< 100","< 200", "> ACK", "> BYE", "< 200"]
    start_controller    
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100","> 200", "< ACK"] 
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::StrayMessageManager.clear_handler
    super
  end
  
end
