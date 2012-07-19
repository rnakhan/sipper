
require 'sip_test_driver_controller'

class UacTrHandlerController < SIP::SipTestDriverController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

  def initialize
    logd('#{name} controller created')
  end

  def start
    session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
    session.request_with('INFO', 'sip:nasir@sipper.com')
  end

  def on_success_res(session)
    session.invalidate(true)
    session.flow_completed_for('TestThTest')
  end

end
