
require 'driven_sip_test_case'

class Test2xxRetransmissionWithTxns < DrivenSipTestCase

  def setup
    super
    Transport::BaseTransport.clear_all_filters
    str = <<-EOF
    
    #-------- Transport Filters------------
    
    require 'transport/base_transport'

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
    
    
    #--------- Controllers ---------------
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class Uas2xx1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        t2xx_usage true
        
        
        def on_invite(session)
          logd("Received INVITE in #{name}")
          r = session.create_response(200, "OK")
          session.send(r)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("Test2xxRetransmissionWithTxns")  
        end
        
        def order
          0
        end
      end
      
      class Uac2xx1Controller < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true        
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from " + name)
        end
     
        def on_success_res(session)
          logd("Received response in " + name)
          session.create_and_send_ack 
          session.invalidate(true) if session['ack_sent']
          session['ack_sent'] = true
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::Uac2xx1Controller")
  end
  
  
  def test_2xx_retransmissions
    self.expected_flow = ["> INVITE","< 100", "< 200 ", "> ACK", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200 {2,2}", "< ACK"]
    verify_call_flow(:in)
  end
  
end



