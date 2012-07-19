
require 'driven_sip_test_case'

class TestStrayInline < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'stray_message_manager'

    class InlineStrayHandler < SIP::StrayMessageHandler
      def handle(m)
        [SIP::StrayMessageHandler::SMH_DROP, m]
      end
    end
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasInlineStrayController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true

 
        def initialize
          logd(name+' controller created')
        end
      
        def on_invite(session)
          session.respond_with(200)
          session.invalidate(true)
        end
      
        
        def on_ack(session)
        end
        
        
        def order
          0
        end
        
      end
      
      class UacInlineStrayController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
          session.invalidate(true)
          session.flow_completed_for('TestStrayInline')
        end
       
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacInlineStrayController")
  end
  
  
  def test_stray_controllers
    self.expected_flow = ["> INVITE", "< 100","< 200", "> ACK"]
    start_controller    
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100","> 200"] 
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::StrayMessageManager.clear_handler
    super
  end
  
end



