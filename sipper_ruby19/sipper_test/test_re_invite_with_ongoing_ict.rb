
require 'driven_sip_test_case'


class TestReInviteWithOngoingIct < DrivenSipTestCase

  def setup
    @orig_compliance = SipperConfigurator[:ProtocolCompliance]
    SipperConfigurator[:ProtocolCompliance]='strict'
    super
    str = <<-EOF
    
    #----- Txn Handler--------
    
    require 'transaction/state_machine_wrapper'
    
    class IctTxnHandler
         
      def before_success_final(txn)
        txn.__consume_msg(true)
        def before_success_final(txn)
          SIP::Transaction::SM_PROCEED
        end
        SIP::Transaction::SM_DO_NOT_PROCEED
      end
      
    end
    #------------------------
    
    
    #------ Controllers -----
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasReInvite2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        t2xx_usage true
        
        def on_invite(session)
          session.respond_with(200)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestReInviteWithOngoingIct")
        end
        
        def order
          0
        end
      end
      
      class UacReInvite2Controller < SIP::SipTestDriverController

        transaction_usage :use_transactions=>true
        transaction_handlers :Ict=>IctTxnHandler

        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          if session['seen_once']
            session.request_with('ack') 
            session.invalidate(true)  
          else
            session['seen_once'] = true
            session.request_with("invite")
          end
        rescue RuntimeError
          session.do_record("existing_ict")
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacReInvite2Controller")
  end
  
  
  def test_reinvite
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! existing_ict", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200 {2,2}", "< ACK"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:ProtocolCompliance] = @orig_compliance
    super
  end
  
end


