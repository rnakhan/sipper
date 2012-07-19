
require 'sip_test_driver_controller'

class StrayUasController < SIP::SipTestDriverController

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

 
  def initialize
    logd('#{name} controller created')
  end

  def on_invite(session)
    session.respond_with(100)
    session.respond_with(200)
    session.invalidate(true)
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
  end

  def on_ack(session)
  end

end
