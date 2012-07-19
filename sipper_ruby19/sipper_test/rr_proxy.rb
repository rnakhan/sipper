
require 'proxy_controller'

class RRProxyController < SIP::ProxyController

  
  transaction_usage :use_transactions=>true
  record_route true
  

  def on_invite(session)
    proxy_to(session, SipperConfigurator[:DefaultRIP], 
      SipperConfigurator[:DefaultRP])
    go_transparent(session)
  end

end
