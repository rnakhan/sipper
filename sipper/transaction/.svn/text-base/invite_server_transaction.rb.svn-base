require 'transaction/Ist_sm'
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
    class InviteServerTransaction < SIP::Transaction::BaseTransaction
      include SipLogger
      include SipperUtil
      
      # to be used for accessing msg for printing/recording
      attr_accessor :msg_sent, :cancel_stxn  
      
      # The transport to use, transport flags, remote ip and port
      # the block is to be used to override the T1, T2, even TimerG etc. timer value. 
      # The block can for example have { self.t1 = 200; self.tg=100 } to override the 
      # T1, A on a transaction by transcation basis, otherwise the default is 
      # taken from SipperConfigurator or SIP::Transaction::BaseTransaction::T1
      # in that order. 
      # Usage: TU creates transaction and starts invoking "Invocation Action" 
      # methods. Also for requests received, checks whether to consume them 
      # or not based on consume?  method return value.
      # There are three call backs into TU from IST and they are notification on 
      # transport error and transaction timeout. 
      # There are 3 TU callbacks. 
      #   (a) transaction_transport_err() gets called should IST get a transport failure 
      #   (b) transaction_timeout() gets called on timeout of transaction
      #   (c) transaction_transaction_cleanup() gets called on transaction termination.
      #   (d) transaction_wrong_state() if the transaction transition is tried in a wrong state
      #       i.e a message is either received or being tried to send out in a state where it is
      #       illegal to do so.
      # 
      def initialize(tu, branch_id, txn_handler, transport, tp_flags, sock = nil, &block)
        @ilog = logger
        @transaction_name = :Ist # need to have this name defined for every transaction
        @tu = tu
        @branch_id = branch_id
        @transport = transport
        @txn_handler = txn_handler
        @tp_flags = tp_flags
        @sock = sock
        self.ti = 0 if @transport.reliable?  # one line later it can be overidden by arguments.
        self.tz = 0 if @transport.reliable?   
        super(&block)  # override timers
        SIP::Transaction::StateMachineWrapper.bootstrap_machine(self, Ist_sm)
        @sm = SIP::Transaction::StateMachineWrapper.new(self, @txn_handler, Ist_sm)
        @ilog.debug("Created the Invite Server Transcation with #{@transport}") if @ilog.debug?
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
      
   
      #--- SM Invocation Actions <start>---------
      
      #------------------
      # The two methods txn_send and txn_received are two general purpose methods
      # that will be called by the TU as against the transcation type specific 
      # methods defined on each type of transaction. 
      #
      # IST sends only responses from TU
      def txn_send(msg)
        @message = msg  # the msg is accessed from transaction
        raise "IST can only send respones" unless msg.is_response? 
        case msg.code
        when 100..199
          _send_provisional(msg)
        when 200..299
          _send_success_final(msg)
        when 300..699
          _send_non_success_final(msg)
        else
          raise "IST cannot deal with this response #{msg}"
        end    
      end
      
      # The IST receives requests INVITE and ACK/3xx-6xx only
      def txn_received(msg)
        @message = msg
        raise "IST can only receive requests" unless msg.is_request?
        case msg.method
        when "INVITE"
          _invite_received(msg)
        when "ACK"
          _ack_received(msg)
        else
          raise "IST cannot deal with this request #{msg}"
        end
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
      
      def _send_success_final(msg)
        @last_response_sent = nil # we do not cache the 2xx response as TU deals with it
        @sm.success_final(msg)
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Cannot send 2xx in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
       
      def _send_non_success_final(msg)
        @last_response_sent = msg
        @ok_to_run_timerH = true unless @transport.reliable?
        @ok_to_run_timerG = true unless @transport.reliable?
        @sm.non_success_final(msg)
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Cannot send non-success-final in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
     
      
      
      def _invite_received(msg)
        @invite = msg  unless @invite
        @sm.invite
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Received an INVITE in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      def _ack_received(msg)
        @sm.ack
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Received an ACK in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      def _cancel_received(msg)
        @sm.cancel
        _check_transport_err
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Received a CANCEL in #{self.state} state for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      
      
      #--- TU Invocation Actions <end>---------
      
      
      #------ Timer callback------
      def on_timer_expiration(timer_task)
        super  # check for invalidation
        case timer_task.tid
        when :th
          @sm.timer_H if @ok_to_run_timerH
          _check_transport_err
        when :tg
          @sm.timer_G(timer_task.duration)  if @ok_to_run_timerG
        when :ti
          @sm.timer_I
        when :tz
          @sm.timer_Z
        end
      rescue Statemap::TransitionUndefinedException => e
        @ilog.error "Timer #{timer_task.tid} got fired for #{self}" if @ilog.error?
        @tu.transaction_wrong_state(self) if @tu
        @txn_handler.wrong_state(self) if @txn_handler && @txn_handler.respond_to?(:wrong_state)
      end
      #----------------------------
      
      
     
      #------SM Callbacks <start>--------
      # in the order of appearance
      def __send_trying
        r = @tu.create_response(100, "Trying")
        @last_sent_response = r
        @ilog.debug "Sending the 100 Trying response from Ist #{self}" if @ilog.debug?
        _send_to_transport(r, @sock)
      end
      
      def __consume_msg(b)
        @consume = b
      end
      
      def __transport_err
        @ilog.error "A transport error was encountered for #{self} calling TU" if @ilog.error?
        @tu.transaction_transport_err(self) if @tu
        @txn_handler.transport_err(self) if @txn_handler && @txn_handler.respond_to?(:transport_err)
      end
      
      def __send_provisional_response(r)
        @ilog.debug "Sending the provisional response #{r.code} from Ist #{self}" if @ilog.debug?
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
      
      def __send_success_response(r)
        @ilog.debug "Sending the 2xx response #{r.code} from Ist #{self}" if @ilog.debug?
        _send_to_transport(r, @sock)
      end
      
      def __send_non_success_final_response(r)
        @ilog.debug "Sending the non-sucess final response #{r.code} from Ist #{self}" if @ilog.debug?
        @last_sent_response = r
        _send_to_transport(r, @sock)
      end

      
      def __create_and_send_487
        r = @tu.rejection_response_with(487, @invite)
        @last_sent_response = r
        @ilog.debug "Sending the 487 response from Ist #{self}" if @ilog.debug?
        _send_to_transport(r, @sock)
      end
      
      def __start_G
        return unless @ok_to_run_timerG
        task = SIP::Locator[:Sth].schedule_for(self, :tg, nil, :transaction, self.tg)
        @ilog.debug("Starting Timer G #{task} from Ist #{self}") if @ilog.debug?
      end
      
      def __start_H
        return unless @ok_to_run_timerH
        task = SIP::Locator[:Sth].schedule_for(self, :th, nil, :transaction, self.th)
        @ilog.debug("Starting Timer H #{task} from Ist #{self}") if @ilog.debug?
      end
      
      def __cancel_G
        @ilog.debug "canceling timer G" if @ilog.debug?
        @ok_to_run_timerG = false
      end
      
      def __cancel_H
        @ilog.debug "canceling timer H" if @ilog.debug?
        @ok_to_run_timerH = false
      end
      
      def __start_I
        task = SIP::Locator[:Sth].schedule_for(self, :ti, nil, :transaction, self.ti)
        @ilog.debug("Starting Timer I #{task} from Ist #{self}") if @ilog.debug?
      end
      
      def __start_Z
        task = SIP::Locator[:Sth].schedule_for(self, :tz, nil, :transaction, self.tz)
        @ilog.debug("Starting Timer Z #{task} from Ist #{self}") if @ilog.debug?
      end
      
      def __reset_G(t)
        self.tg = [2*t, self.t2].min
        __start_G
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
      
      private :_send_to_transport, :_check_transport_err, :_send_non_success_final,
              :_send_success_final, :_send_provisional, :_invite_received, :_ack_received
      
    end
  end
end

