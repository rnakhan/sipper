
require 'proxy_controller'

class CallerPreferenceProxyController < SIP::ProxyController

  
  transaction_usage :use_transactions=>true
  
  def on_invite(session)
    reg_list = registration_store.get(session.irequest.to.header_value)
    # assuming that after applying the matching operation as per RFC 2533, proxy finds this contact 
    session.irequest.uri= reg_list[4].contact_uri
    proxy_to(session, SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
    go_transparent(session)
  end

end
