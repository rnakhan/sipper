require 'base_test_case'
require 'util/timer/timer_task'
require 'ruby_ext/time'
require 'flexmock'

class MyTarget
  attr_accessor :count
  def initialize
    @count = 0
  end
  def on_timer_expiration(timer)
    @count += 1
  end
end

class TestTimerTask < BaseTestCase
  include FlexMock::TestCase
  
  def test_init
    t = SIP::TimerTask.new(nil)
    assert_equal(:session, t.type)
    assert_not_nil(t.abs_msec)
  
    t = SIP::TimerTask.new(nil, lambda {return 99})
    assert_equal(99, t.task.call)  
    
    t = SIP::TimerTask.new(nil) { next 99 }
    assert_equal(99, t.task.call)
    
    # past time
    assert_raise(ArgumentError) { SIP::TimerTask.new(nil, nil, nil, nil, -100) }
    assert_nothing_raised { SIP::TimerTask.new(nil, nil, nil, nil, 0) }
  end
    
  def test_comparison
    t1 = SIP::TimerTask.new(nil, nil, nil, nil, 100)
    t2 = SIP::TimerTask.new(nil, nil, nil, nil, 200)
    assert(t1 < t2)
  end
  
  def test_invocation
    tg = FlexMock.new
    tg.should_receive(:on_timer_expiration).with(SIP::TimerTask).and_return("fine")
    t = SIP::TimerTask.new(tg)
    assert_equal("fine", t.invoke)
  end
  
  def test_cancellation
    tg = MyTarget.new
    t = SIP::TimerTask.new(tg)
    t.invoke
    assert_equal(1, tg.count)
    t = SIP::TimerTask.new(tg)
    t.cancel
    assert(t.canceled?)
    t.invoke
    assert_equal(1, tg.count)
  end
  
end
