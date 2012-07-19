require 'session'
require 'sip_logger'

class UdpSession < Session
  include SipLogger
  
  # TODO: Fix it. 
  # sock doesnt make sense here, done for symmetry with TCP 
  def initialize(rip, rp, rs, session_limit=nil, specified_transport = nil, sock = nil)
    if specified_transport
      tp = SIP::Locator[:Tm].get_udp_transport_with(specified_transport[0], specified_transport[1])
    else
      tp = SIP::Locator[:Tm].get_udp_transport_for(rip, rp) if rip && rp  
    end
    
    super(tp, rip, rp, rs, session_limit)  
  end
  
  def convert_session_to_tcp
    self.transport = nil
    s = Marshal.dump(self)  
  end
end
