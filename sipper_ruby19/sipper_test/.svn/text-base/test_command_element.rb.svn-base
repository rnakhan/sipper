
require 'base_test_case'
require 'util/command_element'
require 'benchmark'

class TestCommandElement < BaseTestCase

  def setup
    super
  end
  
  def test_sleep 
    c = SipperUtil::CommandElement.new("@sleep_ms 33")
    assert_equal("@", c.direction)
    assert_equal("sleep 0.033", c.command_str) # this is actual Ruby command
  end
  
  def test_bad1
    assert_raise(ArgumentError) { SipperUtil::CommandElement.new("<sleep_ms 33") }    
  end
  
  def test_bad2
    assert_raise(ArgumentError) { SipperUtil::CommandElement.new("@") }    
  end
  
  def test_bad3
    assert_raise(ArgumentError) { SipperUtil::CommandElement.new("@sleep_ms -33") }    
  end
  
  def test_actual_sleep_execution
    c = SipperUtil::CommandElement.new("@sleep_ms 500")
    elapsed_time = Benchmark.realtime do 
      eval c.command_str  
    end
    assert_in_delta(0.5, elapsed_time, 0.1)
  end
  
end
