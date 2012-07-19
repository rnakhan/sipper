
require 'transaction/Nict_sm'
require 'transaction/transaction'
require 'transaction/state_machine_wrapper'
require 'util/timer/sip_timer_helper'
require 'sip_logger'
require 'util/locator'
require 'ruby_ext/object'
require 'request'
require 'util/sipper_util'

module SIP
  module Transaction
    class NonInviteClientTransaction < SIP::Transaction::BaseTransaction
      include SipLogger
      
      # to be used for accessing msg for printing/recording
      attr_accessor :msg_sent, :cancel_ctxn  
      
      # The transport to use, transport flags, remote ip and port
      # the block is to be used to override the T1, T2, even TimerA etc. timer value. 
      # The block can for example have { self.t1 = 200; self.te=100 } to override the 
      # T1, E on a transaction by transcation basis, otherwise the default is 
      # taken from SipperConfigurator or SIP::Transaction::BaseTransaction::T1
      # in that order. 
      # Usage: TU creates transaction and starts invoking "Invocation Action" 
      # methods. Also for responses received, checks whether to consume them 
      # or not based on consume?  method return value.
      # There are four call backs into TU from NICT and they are notification on 
      # transport error and transaction timeout. 
      # There are 4 TU callbacks. 
      #   (a) transaction_transport_err() gets called should NICT get a transport failure 
      #   (b) transaction_timeout() gets called on timeout of transaction
      #   (c) transaction_transaction_cleanup() gets called on transaction termination.
      #   (d) transaction_wrong_state() if the transaction transition is tried in a wrong state
      #       i.e a message is either received or being tried to send out in a state where it is
      #       illegal to do so. 
      def initialize(tu, branch_id, txn_handler, transport, tp_flags, sock = nil, &block)
        @ilog = logger
        @transaction_name = :Nict # need to have this name defined for every transaction
        @tu = tu
        @branch_id = branch_id
        @transport = transport
        @txn_handler = txn_handler
        @tp_flags = tp_flags
        @sock = sock
        self.tk = 0 if @transport.reliable?  # one line later it can be overidden by arguments.
        super(&block)  # override timers
        #@sm = Ict_sm.new(self)
        SIP::Transaction::StateMachineWrapper.bootstrap_machine(self, Nict_sm)
        @sm = SIP::Transaction::StateMachineWrapper.new(self, @txn_handler, Nict_sm)
        @ilog.debug("Created the Non Invite Client Transcation with #{@transport}") if @ilog.debug?
      end
      
      
      # Need to handle this after the transition has happened and not in the 
      # _send_to_transport exception handler because state transition from 
      # within a transition is not possible in smc
      def _check_transport_err
        @sm.transport_err if @transport_err
      end
      
      
      #--- SM Invocation Actions <start>---------
      
      #------------------
      # The two methods txn_send and txn_received are two general purpose methods
      # that will be called by the TU as against the transcation type specific 
      # methods defined on each type of transaction. 
      #
      # NICT sends only Non-INVITEs from TU
      def txn_send(msg)
        @message = msg  # the msg is accessed from transaction
        raise "NICT can only send Non INVITEs" unless (msg.is_request? && msg.method!="INVITE") 
        self._send_request(msg)
      end
      
      # The NICT receives responses (provisional and final)
      def txn_received(msg)
        @message = msg
        raise "NICT can only receive responses" unless msg.is_response?
        msg.set_request(@request)
        case msg.code
        when 100..199
          _provisional_received
        when 200..699
          _final_received(msg)
        else
          raise "NICT cannot deal with response #{msg}"
        end    
      end
      #------------------ 
      
      # These method is to be invoked by the TU to send the non-invite
      # The state machine drives the whole interaction by calling the
      # callbacks. 
      
      def _send_request(req)
        @request = req
        @ok_to_run_timerE = true unless @transport.reliable?
        @ok_to_run_timerF = true
        @sm.request
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Cannot send request in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
       
      def _provisional_received
        @sm.provisional
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Received a provisional in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      
      
      def _final_received(res)
        @response = res
        @sm.final
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Received a final response in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      #--- SM Invocation Actions <end>---------
      
      
      #------ Timer callback------
      def on_timer_expiration(timer_task)
        super  # check for invalidation
        case timer_task.tid
        when :te
          @sm.timer_E(timer_task.duration) if @ok_to_run_timerE
          _check_transport_err
        when :tf
          @sm.timer_F  if @ok_to_run_timerF
        when :tk
          @sm.timer_K
        end
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Timer #{timer_task.tid} got fired for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      #----------------------------
      
      
     
      #------SM Callbacks <start>--------
      
      def __send_request
        @ilog.debug "Sending Non-INVITE from the Nict #{self}" if @ilog.debug?
        _send_to_transport(@request, @sock)  
      end
      
      def __start_E
        return unless @ok_to_run_timerE
        task = SIP::Locator[:Sth].schedule_for(self, :te, nil, :transaction, self.te)
        @ilog.debug("Starting Timer E #{task} from Nict #{self}") if @ilog.debug?
      end
      
      def __start_F
        return unless @ok_to_run_timerF
        task = SIP::Locator[:Sth].schedule_for(self, :tf, nil, :transaction, self.tf)
        @ilog.debug("Starting Timer F #{task} from Nict #{self}") if @ilog.debug?
      end
      
      def __start_K
        task = SIP::Locator[:Sth].schedule_for(self, :tk, nil, :transaction, self.tk)
        @ilog.debug("Starting Timer K #{task} from Nict #{self}") if @ilog.debug?
      end
      
      def __reset_E(t=self.t2)
        if t == self.t2
          self.te = self.t2
        else
          self.te = [2*t, self.t2].min
        end
        __start_E
      end
      
      def __timeout
        @ilog.warn("Transaction timeout happened") if @ilog.warn?
        @txn_handler.timeout(self) if @txn_handler && @txn_handler.respond_to?(:timeout)
        @tu.transaction_timeout(self) if @tu
      end
      
      def __cancel_E
        @ilog.debug "canceling timer E" if @ilog.debug?
        @ok_to_run_timerE = false
      end
      
      def __cancel_F
        @ilog.debug "canceling timer F" if @ilog.debug?
        @ok_to_run_timerF = false
      end
      
      def __consume_msg(b)
        @consume = b
      end
      
      
      def __transport_err
        @ilog.error "A transport error was encountered for #{self} calling TU" if @ilog.error?
        @txn_handler.transport_err(self) if @txn_handler && @txn_handler.respond_to?(:transport_err)
        @tu.transaction_transport_err(self) if @tu
      end
      
      def __cleanup
        @ilog.debug "Cleanup called for #{self}" if @ilog.debug?
        @tu.transaction_cleanup(self) if @tu
        @txn_handler.cleanup(self) if @txn_handler && @txn_handler.respond_to?(:cleanup)
      end
      #------SM Callbacks <end>--------
      
      # mask callbacks defined for SM (see Transaction.rb)
      mask_callbacks
      
      private   :_send_to_transport, :_check_transport_err
      protected :_send_request, :_provisional_received,
                :_final_received
      
    end
  end
end
