
require 'driven_sip_test_case'

class Test2xxRetransmissionWithNist < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    #-------- Transport Filters------------
    
    require 'transport/base_transport'
    module TransportHandlerForTestNonInvite2xxModule
      class MyInTransportHandler < Transport::TransportIngressFilter
        def do_filter(msg)
          if msg =~ /200 OK/
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
      class UasNi2xxController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        session_timer #{@grty*5}
        
        def on_message(session)
          logd("Received MESSAGE in "+name)
          session.do_record("MSG_RECVD")
          r = session.create_response(200, "OK")
          session.send(r)
          session.invalidate(true)
          
        end
        
        
        def order
          0
        end
      end
      
      class UacNi2xxController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true        
        transaction_timers :t1=>#{@grty*2} 
        
        def start
          r = Request.create_initial("message", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new MESSAGE from " + name)
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          session.invalidate(true)
          session.flow_completed_for("Test2xxRetransmissionWithNist")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacNi2xxController")
  end
  
  
  def test_2xx_retransmissions
    self.expected_flow = ["> MESSAGE {2,2}", "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< MESSAGE", "! MSG_RECVD", "> 200", "< MESSAGE", "> 200"]
    
    verify_call_flow(:in)
  end
  
  
end
