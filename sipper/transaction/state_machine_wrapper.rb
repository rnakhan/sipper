require 'delegate'
require 'monitor'

module SIP
  module Transaction
    SM_PROCEED = 9000
    SM_PROCEED_NO_ACTION = 9001
    SM_DO_NOT_PROCEED = 9002
    
    class StateMachineWrapper < SimpleDelegator
      include MonitorMixin   # all state transitions are synchronized
      
      @@machines_covered = {}  # names of machines handled.  

      def initialize(ctxt, txn_callback, sm_name)  # the context is the object that is driving the state machine
        super(sm_name.new(ctxt))
        @txn_callback = txn_callback
        @ctxt = ctxt
      end #initialize
      
      def self.bootstrap_machine(ctxt, sm_name)
        unless @@machines_covered[sm_name]
          ctxt.state_machine_transitions.each do |m|
            before = ("before_"+m).to_sym
            after  = ("after_"+m).to_sym
            self.class_eval do
              define_method(before) do
                if @txn_callback && @txn_callback.respond_to?(before)
                  return @txn_callback.send(before, @ctxt)
                else
                  SIP::Transaction::SM_PROCEED
                end
              end
              define_method(after) do
                if @txn_callback && @txn_callback.respond_to?(after)
                  @txn_callback.send(after, @ctxt)
                end
              end
              define_method(m.to_sym) do
                ret = self.send(before)
                return if ret == SIP::Transaction::SM_DO_NOT_PROCEED
                @ctxt.mask_actions if ret == SIP::Transaction::SM_PROCEED_NO_ACTION
                self.synchronize do  # all transitions are lock protected
                  super
                end
                @ctxt.unmask_actions if ret == SIP::Transaction::SM_PROCEED_NO_ACTION
                self.send(after)
              end  
            end 
          end # transition methods
          @@machines_covered[sm_name] = sm_name
        end  
        
      end #bootstrap
      
    end #class
  end
end
