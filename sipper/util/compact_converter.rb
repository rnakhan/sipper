require 'facets/core/hash/inverse'
require 'util/sipper_util'

module SipperUtil

  class CompactConverter
    # Ref : http://www.iana.org/assignments/sip-parameters
    COMP_TO_EXPANDED = {
      "a" => "accept_contact",  
      "u" => "allow_events",
      "i" => "call_id",
      "m" => "contact",
      "e" => "content_encoding",
      "l" => "content_length", 
      "c" => "content_type",
      "o" => "event",
      "f" => "from",
      "y" => "identity",   
      "n" => "identity_info",
      "r" => "refer_to",
      "b" => "referred_by",
      "j" => "reject_contact",
      "d" => "request_disposition",
      "x" => "session_expires",
      "s" => "subject",
      "k" => "supported",
      "t" => "to",
      "v" => "via"  
    }
    
    EXPANDED_TO_COMP = COMP_TO_EXPANDED.invert
    
    def self.get_compact(ex_hdr)
      EXPANDED_TO_COMP[SipperUtil.methodize(ex_hdr.to_s)]
    end
    
    def self.get_expanded(c_hdr)
      SipperUtil.headerize(COMP_TO_EXPANDED[c_hdr.to_s.downcase])
    end
    
    def self.has_compact_form?(ex_hdr)
      EXPANDED_TO_COMP.has_key?(SipperUtil.methodize(ex_hdr.to_s))
    end
    
    def self.has_expanded_form?(c_hdr)
      COMP_TO_EXPANDED.has_key?(c_hdr.to_s.downcase)
    end
    
  end
end
