require 'monitor'
require 'singleton'

module SipperUtil
  class Counter
    include Singleton
    
    def initialize
      @@class_lock = Monitor.new
      @@counter = 0
    end
    
    def next
      @@class_lock.synchronize do
        @@counter += 1
      end
    end
    
    def reset
      @@class_lock.synchronize do
        @@counter = 0
      end
    end 
    
  end
end