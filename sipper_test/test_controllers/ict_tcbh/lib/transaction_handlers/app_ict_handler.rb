require 'transaction/state_machine_wrapper'

class AppIctHandler

  def before_invite(txn)
    txn.message.test_header = "Sipper"
  end
  
  def before_success_final(txn)
    txn.message.test_response_header = "Sipper"
  end
    
end


class AppIctHandlerNoAction

  def before_non_success_final(txn)
    txn.__consume_msg(true)
    SIP::Transaction::SM_PROCEED_NO_ACTION
  end
  
end
