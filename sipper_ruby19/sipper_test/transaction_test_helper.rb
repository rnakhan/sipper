module SipMockTester
  
  class MockTimeTransport
    include SIP::Transport::UnreliableTransport
    attr_accessor :msg
    def initialize
      @msg = []
    end
    def send(m, *remaining)
      @msg << Time.ctm
    end
  end
  
  class MockMsgTransport
    include SIP::Transport::UnreliableTransport
    attr_accessor :msg
    def initialize
      @msg = []
    end
    def send(m, *remaining)
      @msg << m.to_s
    end
  end
 
  class ExceptionalTransportOnNthAttempt
    include SIP::Transport::UnreliableTransport
    def initialize(n)
      @count = 1
      @fail_on = n
    end
    def send *a
      raise if @count == @fail_on
      @count += 1
    end
  end
  
  class Tu
    attr_accessor :txn
    
    def transaction_transport_err(txn)
      @txn = txn
    end
    
    def get_request_destination
      [nil, nil, nil]
    end
    
    def get_response_destination(res)
      [nil, nil, nil]
    end
    
    def transaction_cleanup(txn)
      @txn = txn
    end
    
    def transaction_timeout(txn)
      @txn = txn
    end
    
    def transaction_wrong_state(txn)
      @txn = txn
    end
    
    def transaction_record(direction, msg)
    end
    
    def create_non_2xx_ack(invite, response)
      h = {
            :to => response.to.to_s,
            :cseq => sprintf("%s %s", SipperUtil.cseq_number(invite.cseq),"ACK")
          }
      ack = Request.create_subsequent("ACK", invite.uri, h)
      ack.copy_from(invite, :call_id, :from, :via, :route, :contact, :max_forwards)
      ack
    end
    
    def create_response(code, phrase, request=nil)
      res = Response.create code, phrase  # not using request
    end
    
    def rollback_to_before_request_received_state(request)
      # no op
    end
    
    def rejection_response_with(code, request)
      r = create_response(code, "SELECT", request)
      rollback_to_before_request_received_state(request)
      return r
    end
    
  end
  
  # Plain
  class Tcbh1
    attr_accessor :states
    # for ICT
    def before_invite(txn)
     (@states ||= []) << txn.state
    end 
    def after_invite(txn)
     (@states ||= []) << txn.state
    end
    # for NICT
    def before_request(txn)
     (@states ||= []) << txn.state
    end 
    def after_request(txn)
     (@states ||= []) << txn.state
    end
  end
  
  # Masker
  class Tcbh2
    def before_invite(txn)
      SIP::Transaction::SM_PROCEED_NO_ACTION
    end
    # NICT
    def before_request(txn)
      SIP::Transaction::SM_PROCEED_NO_ACTION
    end
  end
  
  class Tcbh3
    attr_accessor :txn
    def before_invite(txn)
      @txn = txn
      SIP::Transaction::SM_DO_NOT_PROCEED
    end
    # NICT
    def before_request(txn)
      @txn = txn
      SIP::Transaction::SM_DO_NOT_PROCEED
    end
  end
  
  class Tcbh4
    attr_accessor :txn
    def wrong_state(txn)
      @txn = txn
    end
  end
  
  class MockRequest
    def initialize(m)
      @method = m
    end
    def is_request?
      true
    end 
    def method
      @method
    end
    def update_content_length      
    end
  end
  
  class MockResponse
    attr_accessor :code
    def initialize(code)
      self.code = code
    end
    def is_response?
      true
    end
    def to_s
      @code
    end
    def set_request(inRequest)
       @request = inRequest
    end
    def get_reqeust()
       raise "No associated request." unless @request
       return @request
    end
    def update_content_length      
    end
  end
  
end

