require 'base_test_case'
require 'util/timer/timer_task'
require 'util/timer/timer_manager'
require 'ruby_ext/time'
require 'monitor'
require 'flexmock'

class TestTimerManager < BaseTestCase
  include FlexMock::TestCase

  def setup
    @q = []
    @tm = SIP::TimerManager.new(@q)
  end
  
  def test_running
    assert_raise(RuntimeError) { @tm.schedule("something") }
  end
  
  def test_one_task
    @tm.start
    task = FlexMock.new
    task.should_receive(:abs_msec).and_return(Time.ctm+100)
    task.should_receive(:canceled?).and_return(false)
    @tm.schedule(task)
    assert(@q.empty?)
    sleep(0.2)
    assert_equal(task, @q.shift)
  end
  
  def test_many_tasks
    @tm.start
    total = 50
    total.downto(1) do
      time = rand*1000 + 500  #offset to ensure that all are scheduled before anyone fires
      task = SIP::TimerTask.new(nil, nil, nil, nil, time)
      @tm.schedule(task) 
    end
    sleep 3
    assert_equal(total, @q.size)
    @q.each_with_index do |val, idx|
      assert(@q[idx] < @q[idx+1], "idx=#{idx} #{@q[idx].abs_msec} and #{@q[idx+1].abs_msec}") if idx+1 < total
    end
  end

  def test_zero_time_task
    @tm.start
    task = FlexMock.new
    task.should_receive(:abs_msec).and_return(Time.ctm)  
    task.should_receive(:canceled?).and_return(false)
    @tm.schedule(task)
    sleep(0.2)
    assert_equal(task, @q.shift)
  end
  
  def test_canceled_task
    @tm.start
    task = FlexMock.new
    task.should_receive(:abs_msec).and_return(Time.ctm+100)
    task.should_receive(:canceled?).and_return(true)
    @tm.schedule(task)
    assert(@q.empty?)
    sleep(0.2)
    assert(@q.empty?)
  end
  
  def teardown
    @tm.stop
  end
  
end
