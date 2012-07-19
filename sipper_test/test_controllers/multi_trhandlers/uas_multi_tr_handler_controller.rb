require 'base_controller'

class UasMultiTrHandlerController < SIP::BaseController

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

  def initialize
    logd('#{name} controller created')
  end

  def on_info(session)
    if session.irequest.test_header == "bb"
      session.do_record("Transform OK")
    end
    session.respond_with(200)
    session.invalidate(true)
  end

end

=begin
  UAC (only on requests)                                          UAS
  >--Test-Header(xx->yy)(yy->zz) -->-------(zz->aa)(aa->bb)-------->
=end