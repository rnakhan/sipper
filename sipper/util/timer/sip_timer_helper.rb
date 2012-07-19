require 'util/timer/timer_manager'
require 'util/timer/timer_task'

module SIP
  class SipTimerHelper
  
    def initialize(manager)
      @tm = manager
    end
    
    # Have methods for all protocol timers here, along with other type of timers
    # like user level timers
    
    def schedule_for(target, tid, block=nil, type=:session, duration=500)
      task = TimerTask.new(target, block, tid, type, duration)
      @tm.schedule task
      return task
    end
    
    def granularity
      @tm.granularity
    end

    def cancel_timer(task)
       @tm.lock.synchronize do
          task.cancel
       end
    end
  end
end
