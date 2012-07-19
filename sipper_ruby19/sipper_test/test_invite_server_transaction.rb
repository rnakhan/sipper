require 'sip_test_case'
require 'transaction/invite_server_transaction'
require 'request'
require 'response'
require 'sipper_configurator'
require 'util/locator'
require 'transport/rel_unrel'
require 'transaction_test_helper'


class TestInviteServerTransaction < SipTestCase

  def setup
    super
    @t = SipMockTester::MockTimeTransport.new
    @tu = SipMockTester::Tu.new
  end
  
  def test_initial_state
    ist = SIP::Transaction::InviteServerTransaction.new(@tu, nil, nil, @t, nil, nil)
    assert_equal("IstMap.Initial", ist.state)
  end

  # invite in initial state  
  def test_invite_initial
    ist = SIP::Transaction::InviteServerTransaction.new(@tu, nil, nil, @t, nil, nil)
    ist.txn_received SipMockTester::MockRequest.new("INVITE")
    assert_equal("IstMap.Proceeding", ist.state)
    assert_equal(1, @t.msg.length)
    assert(ist.consume?)
  end
    
  # sending provisional in proceeding  
  def test_proceeding_provisional
    ist = SIP::Transaction::InviteServerTransaction.new(@tu, nil, nil, @t, nil, nil)
    ist.txn_received SipMockTester::MockRequest.new("INVITE")  # now in proceeding
    r = SipMockTester::MockResponse.new(180)
    ist.txn_send r
    assert_equal("IstMap.Proceeding", ist.state)
    assert_equal(2, @t.msg.length)
  end
  
  # invite comes in proceeding after just 100 trying being sent
  def test_proceeding_invite1
    t = SipMockTester::MockMsgTransport.new
    ist = SIP::Transaction::InviteServerTransaction.new(@tu, nil, nil, t, nil, nil)
    i = SipMockTester::MockRequest.new("INVITE")  
    ist.txn_received(i)   # now in proceeding
    assert(ist.consume?)
    ist.txn_received(i)   # invite retrasmission
    assert(!ist.consume?)
    assert_equal(2, t.msg.length)
    t.msg.each {|m|  assert_match(/100/, m) }
  end
  
  # invite retrans comes in proceeding after 100 and 180 being sent
  def test_proceeding_invite1
    ist, t, i = _send_initial_invite_with_msg_transport
    assert(ist.consume?)
    r = SipMockTester::MockResponse.new(180)
    ist.txn_send r
    ist.txn_received(i)   # invite retrasmission
    assert(!ist.consume?)
    assert_equal(3, t.msg.length)
    assert_match(/100/, t.msg[0])
    assert_equal(180, t.msg[1])
    assert_equal(180, t.msg[2])
  end
  
  def test_success_final_proceeding_finished
    ist, t, i = _send_initial_invite_with_msg_transport
    ist.tz = 100
    r = SipMockTester::MockResponse.new(200)
    ist.txn_send r # should now be in Finished state
    assert_equal("IstMap.Finished", ist.state)
    ist.txn_received(i)
    assert(!ist.consume?)
    c = SipMockTester::MockRequest.new("CANCEL")
    ist.cancel_received(c, nil)
    assert(ist.consume?)
    sleep 0.2
    assert_equal("IstMap.Terminated", ist.state)
  end
  
  # note: the timers are set to defaults, even if the timers are fired during the 
  # course of the test the message will be retransmitted by this isolated Txn to
  # the isolated transport here. 
  def test_non_sucess_final_proceeding
    ist, t, i = _send_initial_invite_with_msg_transport
    r = SipMockTester::MockResponse.new(400)
    ist.txn_send r # should now be in Completed state
    assert_equal("IstMap.Completed", ist.state)
    ist.txn_received(i)
    assert(!ist.consume?)
    assert_equal(3, t.msg.length)
    assert_match(/100/, t.msg[0])
    assert_equal(400, t.msg[1])
    assert_equal(400, t.msg[2])
  end
  
  
  def test_non_success_final_with_timers_proceeding
    ist, t, i = _send_initial_invite_with_msg_transport
    ist.tg = 50
    ist.th = 1000
    ist.t4 = 200
    r = SipMockTester::MockResponse.new(400)
    ist.txn_send r # should now be in Completed state
    assert_equal("IstMap.Completed", ist.state)
    assert_equal(2, t.msg.length)
    assert_match(/100/, t.msg[0])
    assert_equal(400, t.msg[1])
    sleep 0.5    # next retrans at min(150*2, 200) t=350 
    #assert_equal(5, t.msg.length)
    assert_equal(400, t.msg[2])
    assert_equal(400, t.msg[3])
    assert_equal(400, t.msg[4])
    sleep 1  # timer H should have fired by now. 
    assert_equal("IstMap.Terminated", ist.state)
  end
  
  def test_cancel_proceeding
    ist, t, i = _send_initial_invite_with_msg_transport
    c = SipMockTester::MockRequest.new("CANCEL")  
    ist.cancel_received(c, nil)
    assert(ist.consume?)
    assert_equal(2, t.msg.length)
    assert_match(/100/, t.msg[0])
    assert_match(/487/, t.msg[1])
    assert_equal("IstMap.Completed", ist.state)
  end
  
  def test_ack
    ist, t, i = _send_initial_invite_with_msg_transport
    r = SipMockTester::MockResponse.new(400)
    ist.txn_send r # should now be in Completed state
    a = SipMockTester::MockRequest.new("ACK")  
    ist.txn_received(a)
    assert(ist.consume?)
    assert_equal("IstMap.Confirmed", ist.state)
  end
  
  def test_completed_invite
    ist, t, i = _send_initial_invite_with_msg_transport
    r = SipMockTester::MockResponse.new(400)
    ist.txn_send r # should now be in Completed state
    ist.txn_received(i)
    assert_equal(3, t.msg.length)
    assert_match(/100/, t.msg[0])
    assert_equal(400, t.msg[1])
    assert_equal(400, t.msg[2])
    assert(!ist.consume?)
    a = SipMockTester::MockRequest.new("ACK")  
    ist.txn_received(a)
    assert(ist.consume?)
    assert_equal("IstMap.Confirmed", ist.state)
  end
  

  def test_confirmed_with_timer_I
    ist, t, i = _send_initial_invite_with_msg_transport
    r = SipMockTester::MockResponse.new(400)
    ist.txn_send r # should now be in Completed state
    a = SipMockTester::MockRequest.new("ACK")  
    ist.ti = 100
    ist.txn_received(a)
    assert_equal("IstMap.Confirmed", ist.state)
    ist.txn_received(i)
    assert(!ist.consume?)
    sleep 0.5  # though timer I is 100, we sleep for more to eotsoc
    assert_equal(3, t.msg.length)
    assert_match(/100/, t.msg[0])
    assert_equal(400, t.msg[1])
    assert_equal(400, t.msg[2])
    assert_equal("IstMap.Terminated", ist.state)
  end
  
  def test_wrong_state
    t = SipMockTester::MockMsgTransport.new
    ist = SIP::Transaction::InviteServerTransaction.new(@tu, nil, nil, t, nil, nil)
    i = SipMockTester::MockRequest.new("INVITE")  
    ist.txn_received(i)   # now in proceeding
    r = SipMockTester::MockResponse.new(400)
    ist.txn_send r # should now be in Completed state
    assert_nil(@tu.txn)
    ist.txn_send r  # illegal to send a new response from here
    assert_equal(ist, @tu.txn)
    @tu.txn = nil
    a = SipMockTester::MockRequest.new("ACK")  
    ist.txn_received(a)
    assert_equal("IstMap.Confirmed", ist.state)
    ist.txn_received(a)
    assert_nil(@tu.txn)
    ist.txn_send r  # illegal to send a new response from here
    assert_equal(ist, @tu.txn)
  end
  
  
  def _send_initial_invite_with_msg_transport
    t = SipMockTester::MockMsgTransport.new
    ist = SIP::Transaction::InviteServerTransaction.new(@tu, nil, nil, t, nil, nil)
    i = SipMockTester::MockRequest.new("INVITE")  
    ist.txn_received(i)   # now in proceeding
    [ist, t, i]
  end
  
  private :_send_initial_invite_with_msg_transport
end
