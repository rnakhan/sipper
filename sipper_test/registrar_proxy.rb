
require 'proxy_controller'

class RegistrarProxyController < SIP::ProxyController
      
        transaction_usage :use_transactions=>false
        record_route false
        
        def on_register(session)
          logd("Received REGISTER in "+name)
          r = session.create_response(200, "OK") 
          r.service_route ="sip:"+SipperConfigurator[:LocalSipperIP]+":5069;lr"
          session.send(r)
          session.invalidate(true)
        end
        
        def on_invite(session)
          
          aor = session.irequest.to.header_value
          reg_data = registration_store.get(aor)
          session.irequest.uri = reg_data[0].contact_uri
          session.irequest.push_route(reg_data[0].path)
          
          proxy_to(session, SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
          go_transparent(session)
          
        end
        
      end  
