
require 'sip_test_case'
require 'transaction/non_invite_server_transaction'
require 'request'
require 'response'
require 'sipper_configurator'
require 'util/locator'
require 'transport/rel_unrel'
require 'transaction_test_helper'


class TestNonInviteServerTransaction < SipTestCase

  def setup
    super
    @t = SipMockTester::MockTimeTransport.new
    @tu = SipMockTester::Tu.new
  end
  
  def test_initial_state
    nist = SIP::Transaction::NonInviteServerTransaction.new(@tu, nil, nil, @t, nil, nil)
    assert_equal("NistMap.Initial", nist.state)
  end

  # info in initial state
  def test_info_initial
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")
    assert_equal("NistMap.Trying", nist.state)
    assert(nist.consume?)
  end
    
  def test_info_in_trying
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    r = SipMockTester::MockRequest.new("INFO")
    nist.txn_received r
    assert_equal("NistMap.Trying", nist.state)
    assert(nist.consume?)
    nist.txn_received r
    assert_equal("NistMap.Trying", nist.state)
    assert(!nist.consume?)
  end
  
  # sending provisional in trying  
  def test_trying_provisional
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    r = SipMockTester::MockResponse.new(180) # now in proceeding
    nist.txn_send r
    assert_equal("NistMap.Proceeding", nist.state)
    assert_equal(1, @t.msg.length)
  end
  
  def test_trying_final
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    r = SipMockTester::MockResponse.new(200) # now in completed
    nist.txn_send r
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(1, @t.msg.length)
  end
  
  def test_proceeding_provisional
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    r = SipMockTester::MockResponse.new(180) # now in proceeding
    nist.txn_send r
    assert_equal("NistMap.Proceeding", nist.state)
    assert_equal(1, @t.msg.length)
    nist.txn_send r
    assert_equal("NistMap.Proceeding", nist.state)
    assert_equal(2, @t.msg.length)
  end
  
  def test_proceeding_request
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    rq = SipMockTester::MockRequest.new("INFO")  # now in trying
    nist.txn_received rq
    r = SipMockTester::MockResponse.new(180) # now in proceeding
    nist.txn_send r
    assert_equal("NistMap.Proceeding", nist.state)
    assert_equal(1, @t.msg.length)
    nist.txn_received rq
    assert_equal("NistMap.Proceeding", nist.state)
    assert_equal(2, @t.msg.length)
    assert(!nist.consume?)
  end
  
  def test_proceeding_final
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    nist.txn_send SipMockTester::MockResponse.new(180) # now in proceeding
    assert_equal("NistMap.Proceeding", nist.state)
    assert_equal(1, @t.msg.length)
    nist.txn_send SipMockTester::MockResponse.new(200) # now in completed
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(2, @t.msg.length)
  end
  
  
  def test_completed_request
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    rq = SipMockTester::MockRequest.new("INFO")  # now in trying
    nist.txn_received rq
    r = SipMockTester::MockResponse.new(200) # now in completed
    nist.txn_send r
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(1, @t.msg.length)
    nist.txn_received rq
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(2, @t.msg.length)
    assert(!nist.consume?)
  end
  
  
  def test_completed_final
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    rq = SipMockTester::MockRequest.new("INFO")  # now in trying
    nist.txn_received rq
    r = SipMockTester::MockResponse.new(200) # now in completed
    nist.txn_send r
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(1, @t.msg.length)
    nist.txn_send r
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(1, @t.msg.length)
  end
  
  def test_completed_with_timerJ
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, @t, nil, nil)
    nist.tj = @grty*5
    rq = SipMockTester::MockRequest.new("INFO")  # now in trying
    nist.txn_received rq
    r = SipMockTester::MockResponse.new(200) # now in completed
    nist.txn_send r
    assert_equal("NistMap.Completed", nist.state)
    assert_equal(1, @t.msg.length)
    sleep((@grty*10.0)/1000.0)
    assert_equal("NistMap.Terminated", nist.state)
  end
  
  def test_transport_err_trying
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(1)
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    r = SipMockTester::MockResponse.new(180)
    nist.txn_send r
    assert_equal("NistMap.Terminated", nist.state)
    assert_equal(nist, tu.txn)
  end
  
  def test_transport_err_trying
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(1)
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    r = SipMockTester::MockResponse.new(180)
    nist.txn_send r
    assert_equal("NistMap.Terminated", nist.state)
    assert_equal(nist, tu.txn)
  end
  
  def test_transport_err_proceeding
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(2)
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, t, nil, nil)
    nist.txn_received SipMockTester::MockRequest.new("INFO")  # now in trying
    r = SipMockTester::MockResponse.new(180)
    nist.txn_send r
    assert_equal("NistMap.Proceeding", nist.state)
    nist.txn_send r
    assert_equal("NistMap.Terminated", nist.state)
    assert_equal(nist, tu.txn)
  end
  
  def test_transport_err_completed
    t = SipMockTester::ExceptionalTransportOnNthAttempt.new(2)
    tu = SipMockTester::Tu.new
    nist = SIP::Transaction::NonInviteServerTransaction.new(tu, nil, nil, t, nil, nil)
    rq = SipMockTester::MockRequest.new("INFO")  # now in trying
    nist.txn_received rq
    r = SipMockTester::MockResponse.new(200)
    nist.txn_send r
    assert_equal("NistMap.Completed", nist.state)
    nist.txn_received rq
    assert_equal("NistMap.Terminated", nist.state)
    assert_equal(nist, tu.txn)
  end
  
end

