
# Get a stray 200 OK response and create and send an ACK out of thin air.  
# 
require 'driven_sip_test_case'

class TestStrayResAcked < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'stray_message_manager'
    require 'udp_session'
    
    class ResponseStrayHandler < SIP::StrayMessageHandler
      def handle(m)
        ## ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]
        if m.is_response? && m.rcvd_from_info[0] == "AF_INET"
          remote_ip = m.rcvd_from_info[3]
          remote_port = SipperConfigurator[:LocalTestPort]
          rts = if m[:record_route]
            m.record_routes.reverse
            else
              nil
            end
          s = UdpSession.new(remote_ip, remote_port, rts)
          r = s.create_initial_request("ACK", m.contact.uri)
          r.copy_from(m, :from, :to, :call_id)
          s.send(r)
          s.invalidate(true)
        end
        [SIP::StrayMessageHandler::SMH_HANDLED, nil]
      end
    end
    
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasStrayResAckController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true

 
        def initialize
          logd(name+' controller created')
        end
      
        def on_invite(session)
          sleep 1
          session.respond_with(200)
        end
      
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for('TestStrayResAcked')
        end   
         
        def order
          0
        end
        
      end
      
      class UacStrayResAckController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info",
            :record_route=>"<sip:example1.com;lr>,<sip:example2.com;lr>")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_trying_res(session)
          session.invalidate(true)
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacStrayResAckController")
  end
  
  
  def test_stray_controller_for_res
    self.expected_flow = ["> INVITE", "< 100"]
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



