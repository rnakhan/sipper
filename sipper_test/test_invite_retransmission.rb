
require 'driven_sip_test_case'

class TestInviteRetransmission < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    #----- Txn Handler--------
    require 'transaction/state_machine_wrapper'

    class IstTxnHandler
    
      def before_invite(txn)
        def before_invite(txn)
          SIP::Transaction::SM_PROCEED  
        end
        txn.__consume_msg(true)
        SIP::Transaction::SM_PROCEED_NO_ACTION
      end
      
    end
    #------------------------
    
    
    #------ Controllers -----
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasIstRetransController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        transaction_handlers :Ist=>IstTxnHandler

        def on_invite(session)
          logd("Received INVITE in #{name}")
          session.do_record("First_Invite")
          session.schedule_timer_for("sending_200", #{@grty*4})
        end
        
        def on_timer(session, task)
          logd("Timer invoked in #{name}")
          session.respond_with(200)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestInviteRetransmission")
        end
        
        def order
          0
        end
      end
      
      class UacIstRetransController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true    
        transaction_timers :t1=>#{@grty*2}  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from #{name}")
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          session.create_and_send_ack    
          session.invalidate(true)  
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacIstRetransController")
  end
  
  
  def test_invite_retrans
    self.expected_flow = ["> INVITE {2,}",  "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "! First_Invite", "< INVITE {0,}", "> 200", "< INVITE {0,}",  "< ACK"]
    verify_call_flow(:in)
  end
  
end
