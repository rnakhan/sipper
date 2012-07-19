$:.unshift File.join(File.dirname(__FILE__),"..","sipper")

require 'session_manager'
require 'test/unit'


class TestSessionManager < Test::Unit::TestCase
  
  def setup
    @s = Session.new("tp", "ip", "port")
  end
  
  # REQ> 100<
  def test_find_initial_request_out_on_trying_in
    assert_nil(@s.session_map)
    initial_request_out
    s = SessionManager.find_session("my_call_id", "2345", nil)
    assert_equal(@s, s)
    assert_equal(:half, @s.session_map)
  end
  
  # REQ> 180< CANCEL>
  def test_find_initial_request_out_on_ringing
    initial_request_out
    # now 180 received with To tag
    s = SessionManager.find_session("my_call_id", "2345", "6789")
    assert_equal(@s, s)
    assert_equal(:half, @s.session_map)
    # now a CANCEL goes
    s = SessionManager.find_session("my_call_id", "2345", nil)
    assert_equal(@s, s)
    assert_equal(:half, @s.session_map)
  end
  
  # REQ> <200
  def test_find_initial_request_out_on_success
    initial_request_out
    # now 200 received with To tag
    s = SessionManager.find_session("my_call_id", "2345", "6789", true)
    @s.session_key = "|2345|my_call_id|6789|"
    @s.session_map = :full
    assert_equal(@s, s)
    assert_equal(:full, s.session_map)

    assert(s=SessionManager.find_session("my_call_id", "2345", nil)) # as we are not removing from HDM
    assert_equal("|2345|my_call_id||", s.half_dialog_key)
    #assert_nil SessionManager.find_session("my_call_id", nil, "6789")
  end
  
  # SUB> NOT< 2xx<
  def test_find_subscribe_out_notify_in_success_in
    initial_request_out
    # now receive NOTIFY before 2xx
    s = SessionManager.find_session("my_call_id", "2345", "6789", false)
    @s.session_key = "|2345|my_call_id|6789|"
    @s.session_map = :full
    assert_equal(@s, s)
    assert_equal(:full, s.session_map)
    # but we should still find it in half map
    assert_equal @s, SessionManager.find_session("my_call_id", "2345", nil)
    # and now comes 2xx
    s = SessionManager.find_session("my_call_id", "2345", "6789", true)
    assert_equal(@s, s)
    assert_equal(:full, s.session_map)
    assert(s=SessionManager.find_session("my_call_id", "2345", nil)) # as we are not removing from HDM
    assert_equal("|2345|my_call_id||", s.half_dialog_key)
  end
  
  # REQ< 100>
  def test_initial_request_in_trying_out
    initial_request_in_trying_out
    s = SessionManager.find_session("my_call_id", nil, "1234")
    assert_equal(@s, s)
    assert_equal(:half, s.session_map)
  end
  
  # REQ< 100> 2xx>
  def test_initial_request_in_trying_out_final_out
    initial_request_in_trying_out
    s = SessionManager.find_session("my_call_id", nil, "1234")
    s.local_tag = "2345"
    SessionManager.add_session s, true
    s = SessionManager.find_session("my_call_id", "2345", "1234")
    assert_equal(@s, s)
    assert_equal(:full, s.session_map)
    assert_equal("|2345|my_call_id|1234|", s.session_key)
    # half map should not have it anymore
    assert_nil SessionManager.find_session("my_call_id", nil, "2345")
    # as also the other half
    assert_nil SessionManager.find_session("my_call_id", "1234", nil)
  end
  
  
  def test_remove
    assert_nil  SessionManager.find_session("my_call_id", nil, "1234")
    SessionManager.remove_session @s
    SessionManager.remove_session @s  # seeing nothing untoward happens
    setup
    initial_request_in_trying_out
    assert_equal @s, SessionManager.find_session("my_call_id", nil, "1234")
    SessionManager.remove_session @s
    assert_nil  SessionManager.find_session("my_call_id", nil, "1234")
    # try to remove it again
    SessionManager.remove_session @s
    assert_nil  SessionManager.find_session("my_call_id", nil, "1234")
    # setup again
    setup
    initial_request_in_trying_out
    @s.session_map = nil
    SessionManager.remove_session @s
    # will not remove as we botched the session_map
    assert_equal @s, SessionManager.find_session("my_call_id", nil, "1234")
  end

  def test_clean_all
    initial_request_in_trying_out
    assert_equal @s, SessionManager.find_session("my_call_id", nil, "1234")
    SessionManager.clean_all
    assert_nil  SessionManager.find_session("my_call_id", nil, "1234")
  end
  
    
  def initial_request_out
    @s.local_tag = "2345"
    @s.call_id = "my_call_id"
    # Add on simple request going out
    SessionManager.add_session @s
  end
  
  def initial_request_in_trying_out
    @s.remote_tag = "1234"
    @s.call_id = "my_call_id"
    # Add on trying response going out
    SessionManager.add_session @s
  end
  
  
  def teardown
    SessionManager.clean_all
  end
end