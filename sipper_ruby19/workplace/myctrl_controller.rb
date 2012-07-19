# FLOW : > INVITE, < 200, > ACK
#
require 'base_controller'

class MyctrlController < SIP::BaseController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

  # change the directive below to true to start after loading.
  start_on_load false

  def initialize
    logd('Controller created')
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
    session.request_with('INVITE', 'sip:nasir@sipper.com')
  end

  def on_success_res(session)
    session.request_with('ACK')
    session.invalidate
  end

end
