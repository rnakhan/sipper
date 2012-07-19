require 'util/counter'
require 'message'
require 'sip_logger'
require 'util/sipper_util'
require 'sip_headers/sipuri'

class Request < Message

  include SipLogger
  
  # Headers can be added by an argument hash :to=>"mytoheader" 
  # any "-" in the header replaced by a "_". The other way is to directly 
  # set the header like invite.contact = "blah" in this case also you must also replace 
  # any "-" in header with "_".
 
  attr_accessor :method, :uri, :initial, :session_state_snapshot, :local_cseq_before_send
  
  # system headers
  @str = %q{ @h = {
           :call_id => sprintf("_PH_GCNT_-%d@_PH_LIP_",  Process.pid),
           :from => "Sipper <sip:sipper@_PH_LIP_:_PH_LP_>;tag=_PH_LCTG_",
           :to => "Sut <sip:sut@_PH_RIP_:_PH_RP_>",
           :cseq => sprintf("_PH_LCNTS_ %s", @method),
           :via => "SIP/2.0/_PH_TRANS_ _PH_LIP_:_PH_LP_;branch=z9hG4bK-_PH_LCNTS_-_PH_LCNTR_-_PH_GCNT_-_PH_RND_",
           :contact => "<sip:_PH_LIP_:_PH_LP_;transport=_PH_TRANS_>",
           :max_forwards => "70"
          } }
  
  
  class <<self
    attr_reader :str
  end
  
  Request.class_eval Request.str 
  
  
  def Request.sys_hdrs
    @h.keys
  end
  
  
  def initialize(method, uri, *hh)
    super(*hh)
    @ilog = logger
    @method = method.to_s.upcase
    if uri.class == URI::SipUri
      @uri = uri.dup
    else
      @uri = URI::SipUri.new.assign(uri.to_s)
    end
    @ilog.info("Creating a new #{method} request for #{uri}") if @ilog.info?
  end

  # This is a low level method and allows the caller to custom 
  # create the initial requests. If you do not want to create 
  # (and manage) all individual headers then you should use
  # Session#create_initial_request.
  def Request.create_initial *args
    r = new(*args)
    r.initial = true
    r.incoming = false
    r.create_system_headers
    r.define_from_hash(args[2]) if args[2]
    unless Thread.current[:proxy_initiated]
      r.supported = SipperConfigurator[:SupportedOptionTags]
    end
    return r
  end
  
  # This method should not be used if all you want is to create 
  # a subsequent request from a controller. This is a low level 
  # method and allows the caller to custom create the subsequent
  # requests. If you do not want to manipulate (and manage) all 
  # individual headers then you should use Session#create_subsequent_request.
  def Request.create_subsequent *args
    r = new(*args)
    r.initial = false
    r.incoming = false
    return r
  end
  
  
  def Request.parse(req_arr, recvd_options)
    str = req_arr[0].split     # INVITE sip:sut@202.17.31.207:5060 SIP/2.0
    r = new(str[0].strip, str[1].strip)
    r.parse_headers req_arr[1..-1]
    r.incoming = true
    # According to 3581
    # In fact, the server MUST insert a "received" parameter
    # containing the source IP address that the request came from, even if
    # it is identical to the value of the "sent-by" component.  Note that
    # this processing takes place independent of the transport protocol.
    if r.via 
      r.via.received = recvd_options[:received_ip]
      if r.via.has_param?(:rport)
        r.via.rport = recvd_options[:received_port].to_s
      end
    end
    return r
  end
  
  
  def to_s
    msg = sprintf("%s %s SIP/2.0\r\n", @method, @uri.to_s)
    msg = _format_message(msg)
  end

  def create_system_headers
    instance_eval Request.str
    define_from_hash @h
  end
  
end
