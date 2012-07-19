
require 'sip_test_driver_controller'

class UacMultiTrHandlerController < SIP::SipTestDriverController 

  transaction_usage :use_transactions=>false

  def initialize
    logd('#{name} controller created')
  end

  def start
    session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
    session.request_with('INFO', 'sip:nasir@sipper.com', :test_header => "xx")
  end

  def on_success_res(session)
    session.invalidate(true)
    session.flow_completed_for('TestTransportMultiHandler')
  end

end

=begin
  UAC (only on requests)                                          UAS
  >--Test-Header(xx->yy)(yy->zz) -->-------(zz->aa)(aa->bb)-------->
=end