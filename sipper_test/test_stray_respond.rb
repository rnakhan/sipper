
# Get a subsequent request and create a response to the stray request. 
# 
require 'driven_sip_test_case'

class TestStrayRespond < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'stray_message_manager'
    require 'udp_session'
    
    class ResponsiveStrayHandler < SIP::StrayMessageHandler
      def handle(m)
        ## ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]
        if m.is_request? && m.rcvd_from_info[0] == "AF_INET"
          remote_ip = m.via.received || m.via.sent_by_ip
          remote_port = m.via.sent_by_port
          s = UdpSession.new(remote_ip, remote_port, nil)
          r = s.create_response(200, "SELECT", m)
          s.send(r)
          s.invalidate(true)
        end
        [SIP::StrayMessageHandler::SMH_HANDLED, nil]
      end
    end
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasStrayResponsiveController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true

 
        def initialize
          logd(name+' controller created')
        end
      
        def on_invite(session)
          session.respond_with(200)
        end
      
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for('TestStrayRespond')
        end
        
        def order
          0
        end
        
      end
      
      class UacStrayResponsiveController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
          session.invalidate(true)
        end
       
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacStrayResponsiveController")
  end
  
  
  def test_stray_controller1
    self.expected_flow = ["> INVITE", "< 100","< 200", "> ACK"]
    start_controller    
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100","> 200", "< ACK", "> BYE", "< 200"] 
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::StrayMessageManager.clear_handler
    super
  end
  
end



