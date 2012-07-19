require 'util/counter'
require 'message'
require 'sip_logger'

class Response < Message

  include SipLogger
 
  attr_accessor :code, :status
  attr_writer :local
  STATUS_MESSAGES = {
    100 => "Trying",
    180 => "Ringing",
    182 => "Queued",
    183 => "Session Progress",
    200 => "OK",
    202 => "Accepted",
    300 => "Multiple Choices",
    301 => "Moved Permanently", 
    302 => "Moved Temporarily", 
    305 => "Use Proxy", 
    380 => "Alternative Service", 
    400 => "Bad Request",
    401 => "Unauthorized",  
    402 => "Payment Required", 
    403 => "Forbidden", 
    404 => "Not Found",  
    405 => "Method Not Allowed", 
    406 => "Not Acceptable", 
    407 => "Proxy Authentication Required", 
    408 => "Request Timeout", 
    409 => "Conflict", 
    410 => "Gone", 
    413 => "Request Entity Too Large", 
    414 => "Request-URI Too Long", 
    415 => "Unsupported Media Type", 
    416 => "Unsupported URI Scheme", 
    420 => "Bad Extension", 
    421 => "Extension Required", 
    423 => "Interval Too Brief", 
    480 => "Temporarily Unavailable", 
    481 => "Call/Transaction Does Not Exist", 
    482 => "Loop Detected", 
    483 => "Too Many Hops", 
    484 => "Address Incomplete", 
    485 => "Ambiguous", 
    486 => "Busy Here", 
    487 => "Transaction Canceled", 
    488 => "Not Acceptable Here", 
    491 => "Request Pending", 
    493 => "Undecipherable",
    500 => "Server Error",
    501 => "Not Implemented", 
    502 => "Bad Gateway", 
    503 => "Service Unavailable", 
    504 => "Server Time-out", 
    505 => "Version Not Supported", 
    513 => "Message Too Large", 
    503 => "Service Unavailable",
    600 => "Busy Everywhere",
    603 => "Decline", 
    604 => "Does Not Exist Anywhere", 
    606 => "Not Acceptable" 
  }  
  
  def initialize(code, status=nil, *hh)
    super(*hh)
    @ilog = logger
    @code = code
    if status && status != "SELECT"
      @status = status
    else
      @status = STATUS_MESSAGES[code] 
      unless @status
        @status = STATUS_MESSAGES[(code/100)*100]
      end
    end
    @ilog.info("Creating a new #{code} response") if @ilog.info?
  end
  
  # A low level method that allows to custom create the responses.
  def Response.create *args
    r = new(*args)
    r.incoming = false
    return r
  end
  
  
  def Response.parse(res_arr)
    md = SIP_VER_PATT.match(res_arr[0]) #SIP/2.0 180 Ringing
    str =  md.post_match.strip          # 180 Ringing
    md = /\d+/.match(str)
    r = new(md[0].to_i, md.post_match.strip)
    r.parse_headers res_arr[1..-1]
    r.incoming = true
    return r
  end
  
  def locally_generated?
    @local
  end
  
  def to_s
    msg = sprintf("SIP/2.0 %s %s\r\n", @code, @status)
    msg = _format_message(msg)
  end
  
  # The method is to find out the corresponding request method of the received response.
  def get_request_method
    SipperUtil.cseq_method(self.cseq)  
  end

  def set_request(inRequest)
     @request = inRequest
  end

  def get_request()
     raise "No associated request." unless @request
     return @request
  end
  
end


