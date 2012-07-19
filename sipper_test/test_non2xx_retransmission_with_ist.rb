
require 'driven_sip_test_case'

# On INVITE send a 4xx response and the UAC Ctx shall send an automatic ACK
# this ACK is dropped because of a specialized transport filter and so UAS
# shall retransmist the 4xx response on Timer G. This time the ACK generated 
# by the UAC Ctx (ACK retransmission) is duly received at the UAS and the test 
# ends. 
class TestNon2xxRetransmissionWithIst < DrivenSipTestCase

  def setup
    super
    Transport::BaseTransport.clear_all_filters
    str = <<-EOF
    
    #-------- Transport Filters------------
    
    require 'transport/base_transport'
    module TransportHandlerForTestNon2xxModule
      class MyInTransportHandler < Transport::TransportIngressFilter
        def do_filter(msg)
          if msg =~ /ACK/
            # redefine the method
            def do_filter(msg)
              msg
            end
            return nil
          else
            msg
          end
        end  
      end
    end
    
    
    #--------- Controllers ---------------
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasNon2xxController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        transaction_timers :t1=>#{@grty*2} 
        session_timer #{@grty*10} 
        
        def on_invite(session)
          logd("Received INVITE in #{name}")
          session.respond_with(404)
          session.invalidate
          session.flow_completed_for("TestNon2xxRetransmissionWithIst")
        end
        
        
        def order
          0
        end
      end
      
      class UacNon2xxController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true        
        session_timer #{@grty*8} 
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from " + name)
          u.invalidate
        end
          
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacNon2xxController")
  end
  
  
  def test_2xx_retransmissions
    self.expected_flow = ["> INVITE","< 100", "< 404", "> ACK", "< 404", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 404 {2,2}", "< ACK"]
    verify_call_flow(:in)
  end
  
end
