module SipperHttp
  class SipperHttpServletRequestWrapper
    attr_accessor :req, :res
    def initialize(req, res)
      @req = req
      @res = res
    end
    
    def short_to_s
      @req.request_line  
    end
  end
end