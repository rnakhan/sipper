require 'sip_test_case'
require 'test_completion_signaling_helper'
require 'sipper_configurator'
require 'util/expectation_parser'

class DrivenSipTestCase < SipTestCase
  
  @@now_running = "DrivenSipTestCase"
  
  def start_controller(in_mem_rec=false)
    SipperConfigurator[:SessionTimer] = SIP::Locator[:Sth].granularity # we want a quick invalidation for driven test cases
    # see test_completion_signaling_helper for descriptive comment on this
    # sequence.
    _prep_monitor
    super
    wait_for_signaling
  end
  
  def start_named_controller_non_blocking(name, in_mem_rec=false)
    set_controller(name)
    SipperConfigurator[:SessionTimer] = SIP::Locator[:Sth].granularity # we want a quick invalidation for driven test cases
    # see test_completion_signaling_helper for descriptive comment on this
    # sequence.
    _prep_monitor
    start_the_set_controller(in_mem_rec)
  end
  
  def _prep_monitor
    @sd = SIP::TestCompletionSignalingHelper.prepare_monitor_for(self.class.name.split('::')[-1]) unless @sd  
    @ok_to_wait = true
  end
  
  def wait_for_signaling
    if @ok_to_wait
      SIP::TestCompletionSignalingHelper.wait_for_completion_on(@sd)
      @ok_to_wait = false
    end  
  end
  
  # Runs assertions against the expected flow.
  #  assert_equal("> INFO", record_out.get_recording[0])
  def verify_call_flow(*args)
    
    if current_controller && current_controller.class < SIP::SipTestDriverController
      expectation = @flowarr
      ep = SipperUtil::ExpectationParser.new
      ep.parse(expectation)
      
      case args.length
      when 2
        direction = args[0]
        idx = args[1]
      when 1
        if args[0].class == Symbol
          direction = args[0] 
          idx = 0
        end  
        if args[0].class == Fixnum
          idx = args[0]
        end
      when 0
        idx = 0
      end
      
      unless direction
        dir = ep.exps[0].direction
        if dir == "<"
          direction = :in
        elsif   dir == ">"
          direction = :out
        else
          direction = :neutral
        end
      end
      
      if direction.to_s == "in"
        recording = get_in_recording(idx).get_info_only_recording
      elsif direction.to_s == "out"
        recording = get_out_recording(idx).get_info_only_recording
      else
        recording = get_neutral_recording(idx).get_info_only_recording
      end  
      
      recording.each do |msg|
        begin
          match_result = ep.match(msg)
          assert(match_result[0])
        rescue Test::Unit::AssertionFailedError => e
          raise Test::Unit::AssertionFailedError.new("Expected= #{match_result[1]}  Actual= #{msg}")  
        end
      end
    else
      flunk "The controller #{current_controller} is not a proper controller for flow verification"
    end
  end
  
  
  # Flow(s) are the array of messages with their direction in the form 
  # of arrows. 
  # "INVITE >" indicates an outgoing INVITE request and "180 <" indicates an
  # incoming 180 response. 
  # The expected messages further have a mini grammar to indicate the various
  # options in the expected flow. 
  # * a trailing ? (question) of the arrow indicates an optional message, 100 <? means an optional 100, i.e 0 or 1
  # * a trailing + (plus) of the arrow indicates at least 1 of the message 1 or more
  # * a trailing * (star) of the arrow is for 0 or more of the messages. 
  # Note if the flow is [...."180 <", "180 <", ...] then it means that 2 distinct 180s are expected
  # while a "180 <+" means that exactly "same" 180 response is to be received twice.
  # The responses can also take wildcards like "18x" matches any of the 180-189 response code,
  # 1xx is any provisional response including 100. 
  # Two special modifiers "gt" and "lt" can also be used with the responses with a period in between.
  # "1xx.gt.100 <" indicates an expectation of a 1xx class response but greater than 100.
  # 
  # Expected flow is an array with messages like 
  # ["> INFO", "< 200", "< INFO", "> 200", "> INFO", "< 200"]
  # In order to signal the end of test we need to find the smallest non-repeating pattern in the 
  # expected flow (from the end) and then compare the building actual flow against it. 
  # Whenever flow is complete we signal the test class. 
  def expected_flow=(flowarr)
    @flowarr = flowarr 
  end
  
  def set_controller(name)
    super
  end
  private :_prep_monitor  
end
