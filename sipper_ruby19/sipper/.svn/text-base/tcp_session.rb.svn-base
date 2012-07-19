
require 'session'
require 'sip_logger'

class TcpSession < Session
  include SipLogger
  
  attr_reader :sock
  
  def initialize(rip, rp, rs, session_limit=nil, specified_transport = nil, sock = nil)
    if specified_transport
      tp = SIP::Locator[:Tm].get_tcp_transport_with(specified_transport[0], specified_transport[1])
    else
      tp = SIP::Locator[:Tm].get_tcp_transport_for(rip, rp) if rip && rp  
    end
    @sock = sock
    super(tp, rip, rp, rs, session_limit)  
  end
  
end
