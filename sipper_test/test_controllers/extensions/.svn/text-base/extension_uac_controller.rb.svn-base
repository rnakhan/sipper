
require 'sip_test_driver_controller'

class ExtensionUacController < SIP::SipTestDriverController

  transaction_usage :use_transactions=>false

  def initialize
    logd('#{name} controller created')
  end

  def start
    session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
    r = session.create_initial_request('INVITE', 'sip:nasir@sipper.com', :p_session_record=>"msg-debug")
    r.from = "Test Extension <sip:nasir@sipper.com>;tag=1"
    session.send(r)
  end

  def on_success_res(session)
    session.request_with('ACK')
    session.invalidate(true)
  end

end
