
require 'proxy_controller'

class PathRecordProxyController < SIP::ProxyController

  
  transaction_usage :use_transactions=>false
  record_path true
  

  def on_register(session)
    proxy_to(session, SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
    go_transparent(session)
  end
  
  def on_invite(session)
    proxy_to(session, SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
    go_transparent(session)
  end

end
