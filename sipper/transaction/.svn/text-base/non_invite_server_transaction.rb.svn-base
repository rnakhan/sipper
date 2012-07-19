
require 'transaction/Nist_sm'
require 'transaction/transaction'
require 'transaction/state_machine_wrapper'
require 'util/timer/sip_timer_helper'
require 'sip_logger'
require 'util/locator'
require 'ruby_ext/object'
require 'message'
require 'util/sipper_util'

module SIP
  module Transaction
    class NonInviteServerTransaction < SIP::Transaction::BaseTransaction
      include SipLogger
      include SipperUtil
      
      # msg_sent is to be used for accessing msg for printing/recording. Here cancel_stxn is the
      # CANCEL transaction, though unlikely but still possible for a NIST. 
      # transaction_being_canceled is the Stx that is being canceled if this NIST is 
      # actually a CANCEL transaction itself. This will usually be set to an IST for
      # CANCEL transactions. For all other non CANCEL transactions this will be nil.
      # ok_to_send_481_to_cancel is a boolean that will be set from session when the 
      # conditions are there for 481/CANCEL to be sent. This will be the case when no STx is
      # found on receiving CANCEL and both IST and NIST are in use. 
      attr_accessor :msg_sent, :cancel_stxn, :transaction_being_canceled, :ok_to_send_481_to_cancel
      
      # The transport to use, transport flags, remote ip and port
      # the block is to be used to override the T1 and TimerJ etc. timer value. 
      # The block can for example have { self.t1 = 200; self.tj=100 } to override the 
      # T1, J on a transaction by transcation basis, otherwise the default is 
      # taken from SipperConfigurator or SIP::Transaction::BaseTransaction::T1
      # in that order. 
      # Usage: TU creates transaction and starts invoking "Invocation Action" 
      # methods. Also for requests received, checks whether to consume them 
      # or not based on consume?  method return value.
      # There are three call backs into TU from IST and they are notification on 
      # transport error and transaction timeout. 
      # There are 5 TU callbacks. 
      #   (a) transaction_transport_err() gets called should IST get a transport failure 
      #   (b) transaction_timeout() gets called on timeout of transaction
      #   (c) transaction_transaction_cleanup() gets called on transaction termination.
      #   (d) transaction_wrong_state() if the transaction transition is tried in a wrong state
      #       i.e a message is either received or being tried to send out in a state where it is
      #       illegal to do so.
      #   (e) transaction_record() record the message from the transaction. 
      # 
      def initialize(tu, branch_id, txn_handler, transport, tp_flags, sock = nil, &block)
        @ilog = logger
        @transaction_name = :Nist # need to have this name defined for every transaction
        @tu = tu
        @branch_id = branch_id
        @transport = transport
        @txn_handler = txn_handler
        @tp_flags = tp_flags
        @sock = sock
        self.tj = 0 if @transport.reliable?  # one line later it can be overidden by arguments.
        super(&block)  # override timers
        SIP::Transaction::StateMachineWrapper.bootstrap_machine(self, Nist_sm)
        @sm = SIP::Transaction::StateMachineWrapper.new(self, @txn_handler, Nist_sm)
        @ilog.debug("Created the Non Invite Server Transcation with #{@transport}") if @ilog.debug?
      end
      
      def cancel_received(cancel, cstxn)
        @cancel_stxn = cstxn
        _cancel_received(cancel)
      end
       
      
      # Need to handle this after the transition has happened and not in the 
      # _send_to_transport exception handler because state transition from 
      # within a transition is not possible in smc
      def _check_transport_err
        @sm.transport_err if @transport_err
      end
      
      # RFC 3261 section 9.2 4th para last line
      # A CANCEL request has no impact on the processing 
      # of transactions with any other method (other than INVITE)
      # defined in this specification.
      # 
      def _cancel_received(msg)
        @ilog.debug "Received a CANCEL in #{self.state} state for #{self} doing nothing" if @ilog.debug?
      end
      
   
      #--- SM Invocation Actions <start>---------
      
      #------------------
      # The two methods txn_send and txn_received are two general purpose methods
      # that will be called by the TU as against the transcation type specific 
      # methods defined on each type of transaction. 
      #
      # NIST sends only responses from TU
      def txn_send(msg)
        @message = msg  # the msg is accessed from transaction
        raise "NIST can only send respones" unless msg.is_response? 
        case msg.code
        when 100..199
          _send_provisional(msg)
        when 200..699
          _send_final(msg)
        else
          raise "NIST cannot deal with this response #{msg}"
        end    
      end
      
      # The NIST receives requests other than INVITE and ACK only
      def txn_received(msg)
        @message = msg
        raise "NIST can only receive requests" unless msg.is_request?
        raise "NIST cannot deal with this request #{msg}" if msg.method == "INVITE" || msg.method == "ACK"
        _request_received(msg)
      end
      
      
      #------------------ 
      
      # These methods are to be invoked by the TU to send the responses
      # The state machine drives the whole interaction by calling the
      # callbacks. 
      
      def _send_provisional(msg)
        @last_response_sent = msg
        @sm.provisional(msg)
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Cannot send provisional in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      def _send_final(msg)
        @last_response_sent = msg
        @ok_to_run_timerJ = true unless @transport.reliable?
        @sm.final(msg)
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Cannot send final in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
       
      
      
      def _request_received(msg)
        if msg.method == "CANCEL" 
          if self.transaction_being_canceled
            @ilog.debug("Received a CANCEL in NIST with associated ST, sending 200") if @ilog.debug?
            r = @tu.create_response(200, "OK", msg)
            @sm.cancel_with_st(r)
          elsif self.ok_to_send_481_to_cancel
            @ilog.debug("Received a CANCEL in NIST with NO associated ST, sending 481") if @ilog.debug?
            r = @tu.rejection_response_with(481, msg)
            @sm.cancel_with_no_st(r)  
          else
            @sm.request
          end
        else
          @sm.request
        end
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Received a REQUEST in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      #--- TU Invocation Actions <end>---------
      
      
      #------ Timer callback------
      def on_timer_expiration(timer_task)
        super  # check for invalidation
        case timer_task.tid
        when :tj
          @sm.timer_J if @ok_to_run_timerJ
          _check_transport_err
        end
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Timer #{timer_task.tid} got fired for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      #----------------------------
      
      
     
      #------SM Callbacks <start>--------

            
      def __consume_msg(b)
        @consume = b
      end
      
      def __transport_err
        @ilog.error "A transport error was encountered for #{self} calling TU" if @ilog.error?
        @tu.transaction_transport_err(self) if @tu
        @txn_handler.transport_err(self) if @txn_handler && @txn_handler.respond_to?(:transport_err)
      end
      
      def __send_provisional_response(r)
        @ilog.debug "Sending the provisional response #{r.code} from Nist #{self}" if @ilog.debug?
        @last_sent_response = r
        _send_to_transport(r, @sock)
      end
      
      
      def __send_last_response
        if @last_sent_response
          @ilog.debug "Sending the last response #{@last_sent_response.code} from Ist #{self}" if @ilog.debug?
          _send_to_transport(@last_sent_response, @sock)
        else
          @ilog.warn("No last response available, not sending anything from #{self}") if @ilog.warn?
        end
      end
     
      
      def __send_final_response(r)
        @ilog.debug "Sending a final response #{r.code} from Nist #{self}" if @ilog.debug?
        @last_sent_response = r
        _send_to_transport(r, @sock)
      end

      
      def __start_J
        return unless @ok_to_run_timerJ
        task = SIP::Locator[:Sth].schedule_for(self, :tj, nil, :transaction, self.tj)
        @ilog.debug("Starting Timer J #{task} from Nist #{self}") if @ilog.debug?
      end
      
      def __cancel_J
        @ilog.debug "canceling timer J" if @ilog.debug?
        @ok_to_run_timerJ = false
      end
      
      
      def __timeout
        @ilog.warn("Transaction timeout happened") if @ilog.warn?
        @tu.transaction_timeout(self) if @tu
        @txn_handler.timeout(self) if @txn_handler && @txn_handler.respond_to?(:timeout)
      end
      
      def __wrong_state
        log_and_raise "Cannot send response in wrong state #{self}"
      end
      
      
      def __cleanup
        @ilog.debug "Cleanup called for #{self}" if @ilog.debug?
        @tu.transaction_cleanup(self) if @tu
        @txn_handler.cleanup(self) if @txn_handler && @txn_handler.respond_to?(:cleanup)
      end
      #------SM Callbacks <end>--------
      
      # mask callbacks defined for SM (see Transaction.rb)
      mask_callbacks
      
      private :_send_to_transport, :_check_transport_err, :_send_final,
              :_send_provisional, :_request_received
      
    end
  end
end


