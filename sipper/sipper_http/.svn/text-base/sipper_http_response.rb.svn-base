require 'delegate'

# Wraps the HTTPResponse, with Sipper context data.

module SipperHttp
  class SipperHttpResponse < SimpleDelegator
    
    attr_reader :session, :wrapped_http_res
    
    def initialize(http_res, session)
      super(http_res)  
      @session = session
      @wrapped_http_res = http_res
    end
    
    def dispatch    
      @session.on_http_response(self)  
    end
    
    def code
      @wrapped_http_res.code.to_i  
    end
    
    def [](hdr)
      @wrapped_http_res[hdr.to_s]    
    end
    
    def []=(hdr, val)
      @wrapped_http_res[hdr.to_s] = val    
    end
    
    def short_to_s
      self.inspect  
    end
    
  end
end