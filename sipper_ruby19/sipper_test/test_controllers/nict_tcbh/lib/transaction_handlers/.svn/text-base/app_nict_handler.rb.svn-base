require 'transaction/state_machine_wrapper'

class AppNictHandler

  def before_request(txn)
    txn.message.test_header = "Sipper"
  end
  
  def before_final(txn)
    txn.message.test_response_header = "Sipper"
  end
    
end
