require 'ruby_ext/time'
require 'sip_logger'

# The target can be anything which defines a on_timer method. For our purposes it can be 
# a session for most part and possibly transaction. 
# todo update this doc. 
# type can be :session, :app, :transaction. also note that for both :app and :session
# the target is session. 

module SIP
  class TimerTask
    @@slog = SipLogger['siplog::sip_timermanager']

    include Comparable
    attr_reader :abs_msec, :tid, :task, :target, :type, :duration
    
    def initialize(target, task_proc=nil, tid="sip_task", type=:session, duration=100)
      raise ArgumentError, "Time cannot be in past"  if duration < 0
      @duration = duration
      @target = target
      @type = type
      if task_proc
        @task = task_proc
      elsif block_given?
        @task = Proc.new  # converts the block given to initialize to Proc
      end
      @tid = tid
      @abs_msec = Time.ctm + duration
      @canceled = false
    end
    
    # Compare on time only
    def <=>(that)
      abs_msec <=> that.abs_msec
    end
    
    def invoke
      if @canceled 
        @@slog.info("Not invoking timer #{self} as it is canceled") if @@slog.info?
        return 
      end
      @target.on_timer_expiration self
    end
    
    def canceled?
      @canceled
    end
    
    def cancel
      @canceled = true
      @tid = nil;
      @task = nil;
      @target = nil;
      @type = nil;

      @@slog.info("Canceled the timer #{self}") if @@slog.info?
    end
    
    def short_to_s
      self.to_s
    end
  end
end
