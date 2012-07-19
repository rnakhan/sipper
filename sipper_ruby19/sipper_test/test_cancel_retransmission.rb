
require 'driven_sip_test_case'

# The Client sends a CANCEL to INVITE, the server is using both IST and NIST and though sends
# a 487/INVITE, does not sent a 200/CANCEL forcing retransmissions for CANCEL alone.

class TestCancelRetransmission < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    #----- Txn Handler--------
    require 'transaction/state_machine_wrapper'

    
    class NistTxnHandler
         
      def before_cancel_with_st(txn)
        txn.__consume_msg(true)
        SIP::Transaction::SM_PROCEED_NO_ACTION
      end
      
    end
    #------------------------
    
    
    #------ Controllers -----
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasCancel6Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        transaction_handlers :Nist=>NistTxnHandler
             
        def on_cancel(session)
          tid = nil
          if tid = session['cancel_txn_id']
            if tid == session.irequest.transaction.object_id
              logd("Received CANCEL in "+name)
				logd("sending 200 with txn")
              session.respond_with(200) 
            else
              session.do_record("Error")
              logd("Received CANCEL in "+name)
				logd("txn is not correct")
            end
            session.invalidate(true)
          else
            session['cancel_txn_id'] = session.irequest.transaction.object_id
            logd("Received CANCEL in "+name)
				logd("saving txn_id")
          end
        end
        
        
        def on_invite(session)
        end
        
        
        
        def order
          0
        end
        
      end
      
      
      class UacCancel6Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
          u.create_and_send_cancel_when_ready
        end
     
        
        def on_success_res(session)
          logd("Received success response in "+name)
          session.invalidate
          session.flow_completed_for("TestCancelRetransmission")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacCancel6Controller")
  end
  
  
  def test_cancel6_controllers
    self.expected_flow = ["> INVITE", "< 100", "> CANCEL", "< 487", "> ACK", "> CANCEL", "< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "< CANCEL", "> 487", "< CANCEL {0,}", "> 200 {0,}","< ACK", "< CANCEL {0,}", "> 200"] 
    verify_call_flow(:in)
  end
  
end


