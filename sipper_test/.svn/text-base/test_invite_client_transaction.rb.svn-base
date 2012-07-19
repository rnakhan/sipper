require 'sip_test_case'
require 'transaction/invite_client_transaction'
require 'request'
require 'response'
require 'sipper_configurator'
require 'util/locator'
require 'transport/rel_unrel'
require 'transaction_test_helper'

# SipTestCase because it starts sipper.
class TestInviteClientTransaction < SipTestCase
  
  def setup
    super
    @t = SipMockTester::MockTimeTransport.new
    @tu = SipMockTester::Tu.new
  end
  
  
  def test_initial_state
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    assert_equal("IctMap.Initial", ict.state)
  end
  
  
  # default timer A is 500 ms
  def test_default_timerA
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    sleep 5  
    _assert_deltas(@t, 500, 4) 
  end
  
  def test_override_T1
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) {self.t1 = 100}
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    sleep 2  # you should have invites at [0, 100, 300, 700] -> 0.7 sec
    _assert_deltas(@t, 100, 4)
  end
  
  def test_override_timerA
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) {self.ta = 100}
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    sleep 2  # you should have invites at [0, 100, 300, 700] -> 0.7 sec
    _assert_deltas(@t, 100, 4)
  end
  
  
  def test_default_timerB
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) {self.t1 = 100}
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Calling", ict.state)
    sleep 8  # 64*t1 is when it will terminate
    _assert_deltas(@t, 100, 7)
    assert_equal("IctMap.Terminated", ict.state) # as timer B would have fired by now
  end
  
  def test_override_timerB
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) {self.tb = 100}
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    sleep 0.5
    assert_equal("IctMap.Terminated", ict.state)
  end
  
  def test_provisional
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) { self.t1=100 }
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    ict.txn_received SipMockTester::MockResponse.new(100)
    assert_equal(1, @t.msg.length)
    assert_equal("IctMap.Proceeding", ict.state)
    assert(ict.consume?)
    sleep 0.5
    assert_equal(1, @t.msg.length)  # still not retransmit because provisional stops retransmit.
    # now once in proceeding state a provisional should keep you here
    ict.txn_received SipMockTester::MockResponse.new(100)
    assert_equal("IctMap.Proceeding", ict.state)
    assert(ict.consume?)
  end


  def test_invite_ack
    ict, res = _send_inv_recv_res_send_ack false
    assert_match("INVITE", @tm.msg[0])
    assert_match("ACK", @tm.msg[1])
    assert_match("Via: SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1", @tm.msg[1])  # ACK Via
    assert_match("Cseq: 1 ACK", @tm.msg[1])
    assert_match("To: Sut <sip:sut@127.0.0.1:5061>;tag=123", @tm.msg[1])
    assert_no_match(/tag=123/, @tm.msg[0])
    assert_match("To: Sut <sip:sut@127.0.0.1:5061>", @tm.msg[0])
    assert(ict.consume?)
    assert_equal("IctMap.Completed", @ict.state)
    # resend the 400 response
    ict.txn_received(res)
    assert_equal("IctMap.Completed", @ict.state)
    assert_match("ACK", @tm.msg[2])
    assert(!ict.consume?)
  end
  
  def test_invite_ack_in_proceeding
    ict, res = _send_inv_recv_res_send_ack true
  end

  def test_override_timerD
    orig = SipperConfigurator[:TransactionTimers]
    SipperConfigurator[:TransactionTimers] = { :td=>400 }
    _send_inv_recv_res_send_ack false
    SipperConfigurator[:TransactionTimers] = orig
    assert_equal("IctMap.Completed", @ict.state)
    sleep 1
    assert_equal("IctMap.Terminated", @ict.state)
  end
  
  def test_success_final
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    ict.txn_received SipMockTester::MockResponse.new(180)
    assert_equal(1, @t.msg.length)
    assert_equal("IctMap.Proceeding", ict.state)
    assert(ict.consume?)
    ict.txn_received SipMockTester::MockResponse.new(200)
    assert_equal("IctMap.Terminated", ict.state)
    assert(ict.consume?)
    
    # before prov.
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Calling", ict.state)
    ict.txn_received SipMockTester::MockResponse.new(200)
    assert_equal("IctMap.Terminated", ict.state)
    assert(ict.consume?)  
  end
  
  def test_trans_exception
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(1)
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, t, nil, nil)
    assert_equal("IctMap.Initial", ict.state)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Terminated", ict.state)
  end
  
  def test_trans_exception_on_retransmit
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(2)
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, t, nil, nil)
    assert_equal("IctMap.Initial", ict.state)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Calling", ict.state)
    sleep 1
    assert_equal("IctMap.Terminated", ict.state)
  end
  
  def test_trans_exception_with_tu
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(1)
    assert_nil(@tu.txn)
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, t, nil)
    assert_equal("IctMap.Initial", ict.state)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Terminated", ict.state)
    assert_equal(ict, @tu.txn)
  end
  
  def test_no_timerA_reliable
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) {self.t1 = 100}
    rt = @t.dup                                   # make the 
    rt.extend(SIP::Transport::ReliableTransport)  # transport reliable
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    sleep 2 
    assert(1, rt.msg.length)  # no retransmission with realiable trans
  end
  
  def test_timerB_with_reliable
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, nil, @t, nil, nil) {self.tb = 100}
    rt = @t.dup                                   # make the 
    rt.extend(SIP::Transport::ReliableTransport)  # transport reliable
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    sleep 0.5
    assert_equal("IctMap.Terminated", ict.state)
  end
  
  def test_timerD_with_reliable
    _send_inv_recv_res_send_ack(false, true)  # since timer D is run for 0 time it should be instantanous
    sleep 0.5  # just giving some time for transcation to cleanup.
    assert_equal("IctMap.Terminated", @ict.state)
  end
  
  # default, proceed with no change
  def test_txn_handler1
    tcbh = SipMockTester::Tcbh1.new
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Calling", ict.state)
    assert_equal("IctMap.Initial", tcbh.states[0])  # before
    assert_equal("IctMap.Calling", tcbh.states[1])  # after
    assert_equal(1, @t.msg.length)   
  end
  
  # state change but no action masker
  def test_txn_handler2
    tcbh = SipMockTester::Tcbh2.new
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Calling", ict.state)
    assert_equal(0, @t.msg.length)   
  end
  
  # do not proceed
  def test_txn_handler3
    tcbh = SipMockTester::Tcbh3.new
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, tcbh, @t, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Initial", ict.state)
    assert_equal(0, @t.msg.length)   
    assert(tcbh.txn.is_a?(SIP::Transaction::InviteClientTransaction))
  end
  
  # illegal state test
  def test_txn_handler4
    tcbh = SipMockTester::Tcbh4.new
    ict = SIP::Transaction::InviteClientTransaction.new(@tu, nil, tcbh, @t, nil, nil)
    ict.txn_send SipMockTester::MockRequest.new("INVITE")
    assert_equal("IctMap.Calling", ict.state)
    assert_equal(1, @t.msg.length)
    assert_nil(tcbh.txn)
    ict.txn_send SipMockTester::MockRequest.new("INVITE") # you cannot send an INVITE in Calling.    
    assert(tcbh.txn.is_a?(SIP::Transaction::InviteClientTransaction))
    assert_equal("IctMap.Calling", ict.state)    
  end
  
  def _assert_deltas(t, delta, times)
    1.upto(times-1) do |x|
      # as it is +/- for both timers, and allowing for an error factor of 1 so 3.0
      assert_in_delta(t.msg[x-1]+delta, t.msg[x], SIP::Locator[:Sth].granularity * 3.0)  
      delta *= 2
    end
  rescue Test::Unit::AssertionFailedError
    t.msg.each {|m| print "#{m},"}
    puts
    raise
  end
  
  def _send_inv_recv_res_send_ack(provisional, reliable=false)
    t = SipMockTester::MockMsgTransport.new
    if reliable
      @tm = t.dup
      @tm.extend(SIP::Transport::ReliableTransport)
    else
      @tm = t
    end
    
    inv = Request.create_initial("invite", "sip:nasir@sipper.com")
    inv.max_forwards = "70"
    inv.call_id = "1-234@sipper.com"
    inv.via = "SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK-1-0-1"
    inv.from = "Sipper <sip:sipper@127.0.0.1:5060>;tag=1"
    inv.to = "Sut <sip:sut@127.0.0.1:5061>"
    inv.cseq = "1 INVITE"
    @ict = SIP::Transaction::InviteClientTransaction.new(SipMockTester::Tu.new, nil, nil, @tm, nil, nil)
    
    @ict.txn_send inv
    
    if provisional
      @ict.txn_received SipMockTester::MockResponse.new(183)
      assert_equal("IctMap.Proceeding", @ict.state)
    end
    res = Response.create(400, "Bad Request")
    res.copy_from(inv, :from, :call_id, :cseq, :via, :to)
    res.to = inv.to.to_s + ";tag=123"
    @ict.txn_received(res)
    [@ict, res]
  end
  
  private :_assert_deltas, :_send_inv_recv_res_send_ack
end
