require 'rubygems'
gem 'facets', '= 1.8.54'
#require 'facets/more/pqueue'
require 'ruby_ext/pqueue'
require 'monitor'

require 'sip_logger'
require 'util/sipper_util'

module SIP
  class TimerManager
    include SipLogger
    include SipperUtil
  
    attr_reader :granularity, :lock
    
    MAX_TIME = Time.local(2038, "jan", 1).to_f*1000  # a long time
    
    def initialize(msg_q=nil, granularity=50)
      @ilog = logger
      @msg_q = msg_q 
      #@pqueue = PQueue.new() {|x,y| x<y}
      @pqueue = PQueue.new(lambda {|x,y| x<y})
      @lock = Monitor.new
      @cond = @lock.new_cond
      @granularity = granularity
      @running = false
      @next_schedule = MAX_TIME  
    end
    
    
    def schedule(task)
      log_and_raise "Timer Manager not running", RuntimeError unless @running
      if task.canceled?
        @ilog.warn("TimerTask #{task} is canceled, will not be scheduled") if @ilog.warn?
        return  
      end
      @lock.synchronize do
        @pqueue.push task
        @cond.signal if @next_schedule > task.abs_msec + @granularity 
      end
      task
    end
    
    # possibly keep a separate list and then just gloss over when due.
    def remove_task(task)
    end
    
    def start
      @ilog.info "Starting the TimerManager" if @ilog.info?
      @running = true
      Thread.new do
        @lock.synchronize do
          while @running
            # look for top if not current then wait on cond
            if (t = @pqueue.top) 
              diff = t.abs_msec - Time.ctm
              if diff >= @granularity 
                @next_schedule = t.abs_msec
                @cond.wait(diff/1000.0)
              else
                task = @pqueue.pop
                @msg_q << task unless task.canceled?
              end
            else
              @next_schedule = MAX_TIME
              @cond.wait  
            end
          end #while
        end #lock
      end #thread
    end #def
    
    
    def stop
      @ilog.info "Stopping the TimerManager" if @ilog.info?
      @running = false
    end
    
    
  end
end
