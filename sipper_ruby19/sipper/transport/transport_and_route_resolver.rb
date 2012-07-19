require 'ipaddr'

module Transport

  # This class resolves the address for the next hop destination, looking up the DNS 
  # eventually and returning a tuple of addresses and transport to try. For now we just 
  # do a simple name resolve of one address. 
  # 
  # RFC
  # The destination for the request is then computed.  Unless there is local policy specifying 
  # otherwise, the destination MUST be determined by applying the DNS procedures described in [4] 
  # as follows.  If the first element in the route set indicated a strict router (resulting in 
  # forming the request as described in Section 12.2.1.1), the procedures MUST be applied to the 
  # Request-URI of the request .
  # Otherwise, the procedures are applied to the first Route header field value in the request 
  # (if one exists), or to the request's Request-URI if there is no Route header field present.  
  # These procedures yield an ordered set of address, port, and transports to attempt. 
  class TransportAndRouteResolver
    
    IP = /^(\d{1,3}\.){3}\d{1,3}$/.freeze
    
    def self.ascertain_transport_and_destination(msg, session_class=nil)
    
      # if controller preference set then we chose the transport directly
      session_class = UdpSession unless session_class
      if stp = msg.attributes[:_sipper_controller_specified_transport]
        if session_class == UdpSession || session_class == DetachedSession 
          tp = SIP::Locator[:Tm].get_udp_transport_with(stp[0], stp[1])
        elsif session_class == TcpSession
          tp = SIP::Locator[:Tm].get_tcp_transport_with(stp[0], stp[1])
        else 
          raise "Invalid session type #{session_class}, cannot relate to transport"
        end
      end
      
      dest_uri = nil
      if msg.is_request?
        if msg.attributes[:_sipper_use_ruri_to_send]
          dest_uri = msg.uri  
        elsif msg[:route] && msg[:route].length > 0
          dest_uri = msg.route.uri
        else
          dest_uri = msg.uri
        end
      end
      # now find out rip, rp and transport from destination uri.
      # check out http uri resolution.  Ruby URI library can be used here.
      # Use the 3263 mechanism to look at the right destination and transport to use.
      # For now fail if domain name is given.
      # Assumptions-
      # Assume 5060 if no port is given. 
      # Assume sip:ip:port or sip:user@ip:port or sip:user@ip
      # Assume UDP transport
      
      ip = dest_uri.host if dest_uri && dest_uri.respond_to?(:host)
      
      return [tp, nil, nil] unless IP =~ ip
      
      # simple valiadtion, todo must remove when you have 3263 lookup.
      port = Integer((x=dest_uri.port) ? x : 5060)
     
      
      # todo look for right transport, for now use udp for detached
      
      # here we check if tp is already set as a result of controller specification
      unless tp
        if session_class == UdpSession || session_class == DetachedSession
          tp = SIP::Locator[:Tm].get_udp_transport_for(ip, port) if ip && port
        elsif session_class == TcpSession
          tp = SIP::Locator[:Tm].get_tcp_transport_for(ip, port) if ip && port
        else
          raise "Invalid session type, cannot relate to transport"  
        end  
      end  
      [tp, ip, port]
    end
    
  end
  
end
