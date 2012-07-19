require 'sipper_configurator'
require 'statemap'

module SIP
  module Transaction
    
    T1 = 500 
    T2 = 4000
    T4 = 5000
    Td = 32000  # 17.1.1.2
    
    Transactions = [:Ict, :Nict, :Ist, :Nist]
    
    
    class BaseTransaction
      attr_accessor :branch_id, :transport, :t1, :t2, :t4, :ta, :tb, :td, 
                    :tg, :th, :ti, :tz, :te, :tf, :tk, :tj, :ty,
                    :transaction_name, :txn_handler, 
                    :message # the message is the message being sent or received by this transactions
      
      
      def initialize(&block)
        @ilog = logger
        instance_eval(&block) if block_given? 
      end
      
      
      #------------------
      # The two methods txn_send and txn_received are two general purpose methods
      # that will be called by the TU as against the transcation type specific 
      # methods defined on each type of transaction. 
      def txn_send(msg)
        raise "Unimplemented method txn_send by #{self}"
      end
      
      def txn_received(msg)
        raise "Unimplemented method txn_received by #{self}"
      end
      
      # called when the session is being invalidated
      def invalidate
        @invalidated = true
      end
      #------------------ 
      
      # rewrite SM callbacks for masking
      # each callback has to start with a "__"
      def self.mask_callbacks 
        self.instance_methods(false).grep(/^__/).each do |m|
          mask = ("mask_"+m.to_s)
          alias_method mask, m
          define_method(m.to_sym) do |*args|
            self.send(mask.to_sym, *args)  unless @mask_actions
          end
        end
      end
      
      #---------SM Wrapper calls------
      def mask_actions
        @mask_actions = true
      end
      
      def unmask_actions
        @mask_actions = false
      end
      #------------------------------
      
        
      def state
        if @sm
          @sm.getState.getName
        else
          nil
        end
      end
      
      # Returns the current value and resets the value to false (default).
      def consume?
        c = @consume
        @consume = false
        return c
      end
      
      
       # Returns the transition methods of the state machine. 
      def state_machine_transitions
        @transitions if @transitions 
        @transitions = 
        Kernel.const_get(@transaction_name.to_s + "State").instance_methods(false) - 
          ["Default", "Entry", "Exit"]
      end
      
      # Timer callback
      def on_timer_expiration(timer_task)
        if @invalidated
         @ilog.info("This txn #{self} is invalidated, not firing timer #{timer_task}") if @ilog.info?
         return
        end
      end
        
      def t1
        return @t1 if @t1
        @t1 = @t1 || SipperConfigurator[:TransactionTimers][:t1] || SIP::Transaction::T1
      end
      
      def t2
        return @t2 if @t2
        @t2 = @t2 || SipperConfigurator[:TransactionTimers][:t2] || SIP::Transaction::T2
      end
      
      def t4
        return @t4 if @t4
        @t4 = @t4 || SipperConfigurator[:TransactionTimers][:t4] || SIP::Transaction::T4
      end
      
      # the starting value of timerA. <ICT> 
      def ta
        return @ta if @ta
        @ta = self.t1 || SipperConfigurator[:TransactionTimers][:ta]
      end
      
      # the value of timerB <ICT>
      def tb
        return @tb if @tb
        @tb = self.t1*64 || SipperConfigurator[:TransactionTimers][:tb]
      end
      
      # <ICT>
      def td 
        return @td if @td
        @td = @td || SipperConfigurator[:TransactionTimers][:td] || SIP::Transaction::Td 
      end
      
      # the value if timerY <IST>
      # After having sent CANCEL the INVITE transaction also times out - 
      #  However, a UAC canceling a request cannot rely on receiving a 487 
      #  (Request Terminated) response for the original request, as an 
      #  RFC 2543-compliant UAS will not generate such a response.  
      #  If there is no final response for the original request in 
      #  64*T1 seconds (T1 is defined in Section 17.1.1.1), the client 
      #  SHOULD then consider the   original transaction cancelled and 
      #  SHOULD destroy the client transaction handling the original request. 
      def ty
        return @ty if @ty
        @ty = self.t1*64 || SipperConfigurator[:TransactionTimers][:ty]
      end
      
      # the starting value of timerG <IST>
      def tg
        return @tg if @tg
        @tg = self.t1 || SipperConfigurator[:TransactionTimers][:tg]
      end
      
      # the value of timerH <IST>
      def th
        return @th if @th
        @th = self.t1*64 || SipperConfigurator[:TransactionTimers][:th]
      end
      
      # the value if timerI <IST>
      def ti
        return @ti if @ti
        @ti = self.t4 || SipperConfigurator[:TransactionTimers][:ti]
      end
           
      # the value if timerZ <IST>
      # have a look at sipit bug http://bugs.sipit.net/show_bug.cgi?id=769
      def tz
        return @tz if @tz
        @tz = self.t4 || SipperConfigurator[:TransactionTimers][:tz]
      end
      
      #--- <NICT>-------
      def te
        return @te if @te
        @te = self.t1 || SipperConfigurator[:TransactionTimers][:te]
      end
      
      def tf
        return @tf if @tf
        @tf = self.t1*64 || SipperConfigurator[:TransactionTimers][:tf]
      end
      
      def tk
        return @tk if @tk
        @tk = self.t4 || SipperConfigurator[:TransactionTimers][:tk]
      end
      #--------
      
      # the value if timerJ <NIST>
      def tj
        return @tj if @tj
        @tj = self.t1*64 || SipperConfigurator[:TransactionTimers][:tj]
      end
      
      def _send_to_transport(msg, sock=nil)
        msg.update_content_length()
        if msg.is_request?
          rd = @tu.get_request_destination()
        else
          rd = @tu.get_response_destination(msg)
        end
        @transport = rd[0] if rd[0]
        @msg_sent = @transport.send(msg, @tp_flags, rd[1], rd[2], sock)
        @ilog.debug("Now record the outgoing message from #{self.transaction_name}") if @ilog.debug?
        @tu.transaction_record("out", msg)
      rescue 
        @transport_err = true
      end
      
      protected :_send_to_transport  
    end
  end
end
