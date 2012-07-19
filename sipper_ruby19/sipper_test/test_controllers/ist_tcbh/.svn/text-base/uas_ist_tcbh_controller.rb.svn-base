require 'sip_test_driver_controller'
require 'app_ist_handler'

module SipIst
  class  UasIstTcbhController < SIP::SipTestDriverController
    transaction_handlers :Ist=>AppIstHandler
    transaction_usage :use_transactions=>false, :use_ist=>true
    transaction_timers :tz=>50
    def on_invite(session)
      logd("Received INVITE in #{name}")
      session.local_tag = 5  #todo differentiate automatically on the same container somehow
      session.respond_with(200)
      session['txn'] = session.irequest.transaction
    end
    
    def on_ack(session)
      sleep 0.1
      # the tcbh sets a header on the response
      # note: it is better to use hash access for custom headers because if they are not
      # created you will not get a method missing exception.
      session.do_record("Header found") if session['txn'].message[:terminal_header]
      session.invalidate
      session.flow_completed_for("TestControllerUsingIstWithTcbh")
    end
    
    def order
      0
    end
       
  end
end