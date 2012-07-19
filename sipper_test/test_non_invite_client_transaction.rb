
require 'sip_test_case'
require 'transaction/non_invite_client_transaction'
require 'request'
require 'response'
require 'sipper_configurator'
require 'util/locator'
require 'transport/rel_unrel'
require 'transaction_test_helper'

# SipTestCase because it starts sipper.
class TestNonInviteClientTransaction < SipTestCase
  
  def setup
    super
    @t = SipMockTester::MockTimeTransport.new
    @tu = SipMockTester::Tu.new
  end
  
  
  def test_initial_state
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    assert_equal("NictMap.Initial", nict.state)
  end
  
  
  # default timer E is 500 ms
  def test_default_timerE
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    sleep 5  
    _assert_deltas(@t, 500, 4)  
  end
  
  def test_override_T1
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.t1 = @grty*2
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    sleep((@grty*200)/1000.0)  # 2 sec for 50 msec grty
    _assert_deltas(@t, @grty*2, 4)
  end
  

  def test_timerE_F
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.t1 = @grty*2  
    nict.t2 = @grty*4  
    nict.tf = @grty*25 
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    assert_equal("NictMap.Trying", nict.state)
    sleep((@grty*35)/1000.0)  # 1.5 secs
    assert(@t.msg.length >= 6) # at least 6 
    assert_equal("NictMap.Terminated", nict.state) # as timer F would have fired by now
  end
  
  
  def test_provisional
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.t1 = @grty*2 
    nict.t2 = @grty*10  
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    nict.txn_received SipMockTester::MockResponse.new(100)
    assert_equal(1, @t.msg.length) 
    assert_equal("NictMap.Proceeding", nict.state)
    assert(nict.consume?)
    sleep((@grty*18)/1000.0)
    assert_equal(3, @t.msg.length) 
    # now once in proceeding state a provisional should keep you here
    nict.txn_received SipMockTester::MockResponse.new(100)
    assert_equal("NictMap.Proceeding", nict.state)
    assert(nict.consume?)
  end
  
  def test_timerF_with_reliable
    @t.extend(SIP::Transport::ReliableTransport)
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.t1 = @grty #50
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    sleep((@grty*70)/1000.0)
    assert_equal(1, @t.msg.length)
  end
  
  
  def test_final_in_trying
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.t1 = @grty*2 #100
    nict.tk = @grty*20 #1000
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    nict.txn_received SipMockTester::MockResponse.new(200)
    assert(nict.consume?)
    sleep((@grty*4)/1000.0)  # see after twice timer E
    assert_equal(1, @t.msg.length)  # no retrans
    assert_equal("NictMap.Completed", nict.state)
    nict.txn_received SipMockTester::MockResponse.new(200) # a 2xx retrans
    assert(!nict.consume?)
    assert_equal("NictMap.Completed", nict.state)
    sleep((@grty*20)/1000.0) # sleep one full sec
    assert_equal("NictMap.Terminated", nict.state)
  end

  def test_final_in_proceeding
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    nict.t1 = @grty*2 #100
    nict.tk = @grty*20 #1000
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    nict.txn_received SipMockTester::MockResponse.new(100)
    assert(nict.consume?)
    assert_equal("NictMap.Proceeding", nict.state)
    sleep((@grty*4)/1000.0)  # see after twice timer E
    assert(@t.msg.length>1)  # some retrans
    nict.txn_received SipMockTester::MockResponse.new(200)
    msg_so_far = @t.msg.length
    assert(nict.consume?)
    sleep((@grty*4)/1000.0)  # see further after twice timer E
    assert_equal(msg_so_far, @t.msg.length)  # no further retrans
    assert_equal("NictMap.Completed", nict.state)
    nict.txn_received SipMockTester::MockResponse.new(200) # a 2xx retrans
    assert(!nict.consume?)
    sleep((@grty*4)/1000.0)  # see further after twice timer E
    assert_equal(msg_so_far, @t.msg.length)  # no further retrans
    assert_equal("NictMap.Completed", nict.state)
    sleep((@grty*15)/1000.0) # sleep further till termination
    assert_equal("NictMap.Terminated", nict.state)
  end


  def test_trans_exception1
    tu = SipMockTester::Tu.new
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(1)
    nict = SIP::Transaction::NonInviteClientTransaction.new(tu, nil, nil, t, nil, nil)
    assert_equal("NictMap.Initial", nict.state)
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    assert_equal("NictMap.Terminated", nict.state)
    assert_equal(nict, tu.txn)
  end
  
  def test_trans_exception2
    tu = SipMockTester::Tu.new
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(2)
    nict = SIP::Transaction::NonInviteClientTransaction.new(tu, nil, nil, t, nil, nil)
    nict.te = @grty*2
    assert_equal("NictMap.Initial", nict.state)
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    assert_equal("NictMap.Trying", nict.state)
    assert_nil(tu.txn)
    sleep((@grty*4)/1000.0)  # sleep twice timer E 
    assert_equal("NictMap.Terminated", nict.state)
    assert_equal(nict, tu.txn)
  end
  

  # default, proceed with no change
  def test_txn_handler1
    tcbh = SipMockTester::Tcbh1.new
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    assert_equal("NictMap.Trying", nict.state)
    assert_equal("NictMap.Initial", tcbh.states[0])  # before
    assert_equal("NictMap.Trying", tcbh.states[1])   # after
    assert_equal(1, @t.msg.length)   
  end
  
  
  # state change but no action masker
  def test_txn_handler2
    tcbh = SipMockTester::Tcbh2.new
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    nict.txn_send SipMockTester::MockRequest.new("MESSAGE")
    assert_equal("NictMap.Trying", nict.state)
    assert_equal(0, @t.msg.length)   
  end
  
  # do not proceed
  def test_txn_handler3
    tcbh = SipMockTester::Tcbh3.new
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    assert_equal("NictMap.Initial", nict.state)
    assert_equal(0, @t.msg.length)   
    assert(tcbh.txn.is_a?(SIP::Transaction::NonInviteClientTransaction))
  end
  
  # illegal state test
  def test_txn_handler4
    tcbh = SipMockTester::Tcbh4.new
    nict = SIP::Transaction::NonInviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    nict.txn_send SipMockTester::MockRequest.new("INFO")
    assert_equal("NictMap.Trying", nict.state)
    assert_equal(1, @t.msg.length)
    assert_nil(tcbh.txn)
    nict.txn_send SipMockTester::MockRequest.new("MESSAGE") # you cannot send a request in Calling.    
    assert(tcbh.txn.is_a?(SIP::Transaction::NonInviteClientTransaction))
    assert_equal("NictMap.Trying", nict.state)    
  end
  
  def _assert_deltas(t, delta, times)
    1.upto(times-1) do |x|
      # as it is +/- for both timers, and allowing for an error factor of 1 so 3.0
      assert_in_delta(t.msg[x-1]+delta, t.msg[x], SIP::Locator[:Sth].granularity * 3.0)  # as it is +/- for both timers
      delta *= 2
    end
  rescue Test::Unit::AssertionFailedError
    t.msg.each {|m| print "#{m},"}
    puts
    raise
  end
  
  private :_assert_deltas
end

