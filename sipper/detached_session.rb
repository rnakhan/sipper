require 'session'
require 'sip_logger'

class DetachedSession < Session
  include SipLogger
  
  # TODO: Fix it. 
  # sock doesnt make sense here, done for symmetry with TCP 
  def initialize(rip, rp, rs, session_limit=nil, sepecified_transport=nil, sock=nil)
    super(nil, nil, nil, rs, session_limit)  
  end
  
end