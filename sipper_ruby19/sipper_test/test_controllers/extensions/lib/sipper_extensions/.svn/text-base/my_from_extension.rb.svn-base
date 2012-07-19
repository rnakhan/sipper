require 'sip_headers/header'

module SipHeaders
  class From < AddressHeader
  
    alias_method :orig_format, :_format
    
    def _format
      @display_name.upcase! if @display_name && @display_name == "Test Extension"
      orig_format
    end
    
    private :_format, :orig_format 
    
  end
end
