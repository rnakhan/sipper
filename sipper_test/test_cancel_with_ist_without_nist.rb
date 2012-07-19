
require 'driven_sip_test_case'

# The Client sends a CANCEL to INVITE, the server is using IST but not using NIST.

class TestCancelWithIstWithoutNist < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    #----- Txn Handler--------
    require 'transaction/state_machine_wrapper'

    class IstTxnHandler
    
      def after_ack(txn)
        txn.__consume_msg(true)
        SIP::Transaction::SM_PROCEED  
      end
      
    end
    #------------------------
    
    
    #------ Controllers -----
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasCancel5Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_ist=>true
        transaction_handlers :Ist=>IstTxnHandler
             
        def on_cancel(session)
          session.respond_with(200)
        end
        
        def on_invite(session)
        end
        
        # Usually the controller will not see ACK for 4xx response
        # we use the transcation handler to change the consume flag
        # in this case. 
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestCancelWithIstWithoutNist")
        end
        
        def order
          0
        end
        
      end
      
      
      class UacCancel5Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
          u.create_and_send_cancel_when_ready
        end
     
        def on_failure_res(session)
          logd("Received failure response in #{name}")
          if session.iresponse.get_request_method == "INVITE"
            session.invalidate(true)
          end
        end
        
        def on_success_res(session)
          logd("Received success response in #{name}")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacCancel5Controller")
  end
  
  
  def test_cancel5_controllers
    self.expected_flow = ["> INVITE", "< 100", "> CANCEL", "< 200", "< 487", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "< CANCEL", "> 200", "> 487", "< ACK"] 
    verify_call_flow(:in)
  end
  
end


