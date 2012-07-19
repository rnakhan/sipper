
# Get a subsequent request and modify and retry. 
# 
require 'driven_sip_test_case'

class TestStrayRetry < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'stray_message_manager'
    require 'udp_session'
    
    class RetryStrayHandler < SIP::StrayMessageHandler
      def handle(m)
          m.from.tag = m.from.orig_tg
        [SIP::StrayMessageHandler::SMH_RETRY, m]
      end
    end
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasStrayRetryController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
 
        def initialize
          logd(name+' controller created')
        end
      
        def on_invite(session)
          session.respond_with(200)
        end
      
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for('TestStrayRetry')
        end
        
        
        def order
          0
        end
        
      end
      
      class UacStrayRetryController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          ack = session.create_2xx_ack
          ack.from.orig_tg = ack.from.tag
          ack.from.tag = "bad_tag"
          session.send(ack)
          session.invalidate(true)
        end
       
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacStrayRetryController")
  end
  
  
  def test_stray_controller1
    self.expected_flow = ["> INVITE", "< 100","< 200", "> ACK"]
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
