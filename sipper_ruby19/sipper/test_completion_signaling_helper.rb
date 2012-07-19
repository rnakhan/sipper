require 'monitor'
require 'ostruct'
require 'util/locator'

module SIP

  class TcshProxy
    def signal_waiting_test(test_name)
      SipLogger['siplog::sip_testcompletionsignalinghelper'].debug("Fetching the signal data for remote server")
      TestCompletionSignalingHelper.signal_waiting_test(test_name, true)
    end
  end
  
  class TestCompletionSignalingHelper
    include SipLogger
    
    @@ro = nil
    
    # The breakdown into two following methods: one to be called before starting any SIP 
    # signaling and other to be called after having started  the controllers, is to set the monitor 
    # infra in place, such that in the unlikely event of SIP signaling completing before the driver
    # even waits for the signal. 
    
    def self.prepare_monitor_for(test_class_name)
      test_running = []
      test_running.extend(MonitorMixin)
      compl_cond = test_running.new_cond
      signal_data = OpenStruct.new
      signal_data.lock = test_running
      signal_data.cond = compl_cond
      (SIP::Locator[:Tlocks] ||= {})[test_class_name.to_s] = signal_data
    end
    
    # todo make use of count_waiters and signal added to the test_running[]
    def self.wait_for_completion_on(signal_data)
      signal_data.lock.synchronize do
        if signal_data.lock.count{|i| !i.nil?} > 0
          SipLogger['siplog::sip_testcompletionsignalinghelper'].debug "Found queued signal, clearing"
          signal_data.lock.clear
        else
          SipLogger['siplog::sip_testcompletionsignalinghelper'].debug "Now waiting for the signal"
          k = 0
          while k < SipperConfigurator[:WaitSecondsForTestCompletion]
            signal_data.cond.wait(3)
            k += 3
            if signal_data.lock.count{|i| !i.nil?} > 0
              break
            end
          end
          if k >= SipperConfigurator[:WaitSecondsForTestCompletion]
            puts "Timeout happened waiting for signaling completion"
            SipLogger['siplog::sip_testcompletionsignalinghelper'].error "Timeout happened waiting for signaling completion"
          end
        end
      end
    end
    
    
    def self.signal_waiting_test(test_name, proxy_call=false)
      signal_data = SIP::Locator[:Tlocks][test_name] if SIP::Locator[:Tlocks]
      unless signal_data
        unless proxy_call 
          SipLogger['siplog::sip_testcompletionsignalinghelper'].debug "Signaling the remote object"
          @@ro = DRbObject.new(nil, "druby://#{SipperConfigurator[:TestManagerName]}:#{SipperConfigurator[:TestManagerPort]}")  unless @@ro
          signal_data = @@ro.signal_waiting_test(test_name)
          return true
        else
          SipLogger['siplog::sip_testcompletionsignalinghelper'].debug "No SD anywhere"
          return false
        end
      end
      signal_data.lock.synchronize do 
        signal_data.lock << "signal"
        if signal_data.cond.instance_variable_get(:@cond).instance_variable_get(:@waiters).length > 0 
          SipLogger['siplog::sip_testcompletionsignalinghelper'].debug("Signaling the waiting test driver")
          signal_data.cond.signal
        else
          SipLogger['siplog::sip_testcompletionsignalinghelper'].debug "Queueing the signal"
        end
      end
    end
     
  end
end
