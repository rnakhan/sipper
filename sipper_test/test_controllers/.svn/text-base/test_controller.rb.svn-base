require 'base_controller'


class TestController < SIP::BaseController

  start_on_load :true
  transaction_usage :use_transactions=>true, :use_ict=>false, :use_nict=>true, :use_ist=>false, :use_nist=>true
  transaction_timers :t1=>200, :tb=>16000
  
  def on_invite(session)
  end
  
  def on_success_res(session)
  end

  def start
    return true
  end
  
  def get_test_session
    u = create_udp_session("127.0.0.1", 6061)
  end  
  
end