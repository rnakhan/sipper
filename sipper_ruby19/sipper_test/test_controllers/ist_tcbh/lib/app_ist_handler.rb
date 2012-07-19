require 'transaction/state_machine_wrapper'

class AppIstHandler
  
  def before_success_final(txn)
    txn.message.test_response_header = "Sipper"
  end

  def before_timer_Z(txn)
    txn.message.terminal_header = "Sipper"  # This message must be 2xx as it was last received
  end
      
end
