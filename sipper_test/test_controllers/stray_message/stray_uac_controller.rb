
require 'sip_test_driver_controller'

class StrayUacController < SIP::SipTestDriverController

  transaction_usage :use_transactions=>false

  def initialize
    logd('#{name} controller created')
  end

  def start
    session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
    r = session.create_initial_request('INVITE', 'sip:nasir@sipper.com', :p_session_record=>"msg-debug")
    session.send(r)
  end

  def on_success_res(session)
    session.request_with('ACK')
    session.invalidate(true)
    session.flow_completed_for('TestStray')
  end

end
