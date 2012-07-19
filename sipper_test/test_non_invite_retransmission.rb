
require 'driven_sip_test_case'

class TestNonInviteRetransmission < DrivenSipTestCase

  def setup_once
    super
    tid = nil
    str = <<-EOF
    
    #----- Txn Handler--------
    require 'transaction/state_machine_wrapper'

    
    class NistTxnHandler
         
      def before_request(txn)
        txn.__consume_msg(true)
        SIP::Transaction::SM_PROCEED_NO_ACTION
      end
      
    end
    #------------------------
    
    
    #------ Controllers -----
    require 'sip_test_driver_controller'
    module SipInline
    
      class UasNist1Controller < SIP::SipTestDriverController
      
        transaction_usage    :use_transactions=>true
        transaction_handlers :Nist=>NistTxnHandler
        
        def on_info(session)
          if tid = session['nist_txn_id']
            if tid == session.irequest.transaction.object_id
              logd("Received INFO in #{name} sending 200 with txn " + tid.to_s)
              session.respond_with(200) 
            else
              session.do_record("Error")
              logd("Received INFO in #{name} txn is not correct " + tid.to_s)
            end
            session.invalidate(true)
          else
            session['nist_txn_id'] = session.irequest.transaction.object_id
            logd("Received INFO in #{name} saving txn_id " + session['nist_txn_id'].to_s )
          end
        end
        
        
        def order
          0
        end
         
      end
      
      class UacNict1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from #{name}")
        end
    
        
        def on_success_res(session)
          logd("Received response in #{name}")
          session.invalidate(true)
          session.flow_completed_for("TestNonInviteRetransmission")
        end  
      end 
      
    end
    EOF
    define_controller_from(str)
  end
  
  
  def test_nict_retrans
    self.expected_flow = ["> INFO {2,}", "< 200"]
    start_named_controller("SipInline::UacNict1Controller")
    verify_call_flow(:out)
    self.expected_flow = ["< INFO {2,}", "> 200"]  # one retrans
    verify_call_flow(:in)
  end
  
end
