require 'sip_logger'
require 'ruby_ext/string'
require 'util/timer/timer_task'
require 'sip_headers/header'
require 'util/compact_converter'
require 'util/sipper_util'
require 'media/sipper_media_event'
require 'sipper_http/sipper_http_response'

class Message

  include SipLogger
  include Enumerable
  
  @@slog = SipLogger['siplog::message']

  attr_accessor  :incoming, :rcvd_from_info, :rcvd_at_info, :transaction
  
  attr_reader :sdp, :multipart_content
  
  SIP_VER_PATT = /((?i)sip)\/[0-9]+\.[0-9]+/  unless defined? SIP_VER_PATT
  TAGP_C = /(tag=)(.*?);/  unless defined? TAGP_C
  TAGP_E = /(tag=)(.*?)$/ unless defined? TAGP_E

  def initialize(*hh)
    @headers = {}
    define_from_hash hh[0] unless hh[0].nil?
    #populated only for incoming messages
    @rcvd_from_info = nil
    @separate_mv_hdrs ||= []
  end
  
  def attributes
    @attrs ||= {}
  end
  
  def is_request?
    self.class == Request
  end
  
  def is_response?
    self.class == Response
  end
  
  def Message.parse msg
    # If the message is a SIP message received on wire then it of the form
    #["msg", ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
    # otherwise it could be a timer task
    return msg if msg.class <= SIP::TimerTask
    return msg if msg.class <= Media::SipperMediaEvent
    return msg if msg.class <= SipperHttp::SipperHttpResponse
    msg_arr = msg[0].split("\n")
    #SipLogger['siplog::message'].debug("In Message.parse_msg, rcvd from info is #{msg[1]}")
    idx = SIP_VER_PATT =~ msg_arr[0]
    raise ArgumentError, "Not a SIP message" unless idx
    case 
    when idx==0
      @@slog.debug("Parsing received response") if @@slog.debug?
      r = Response.parse msg_arr
    when idx > 0
      @@slog.debug("Parsing received request") if @@slog.debug?
      r = Request.parse( msg_arr, :received_ip=>msg[1][3], :received_port=>msg[1][1] )
    else
      raise ArgumentError, "Not a SIP message"
    end
    r.rcvd_from_info = msg[1] #["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]
    r.rcvd_at_info = msg[2] #[ip, port, tid, sock (in case of TCP)]
    return r
  end
  
  
  def each &block
    @headers.each(&block)
  end
  
  def each_header &block
    @headers.each_key(&block)
  end
  
  def each_value &block
    @headers.each_value(&block)
  end
  
  def define_from_hash(header_hash)
    if @@slog.info?
      header_hash_formatted = header_hash.map{|e| "#{e[0]}: <#{e[1]}>"}.join(', ') 
      @@slog.info("Defining headers from hash #{header_hash_formatted}") 
    end 
    k = nil
    v = nil
    header_hash.each { |k,v| self.send((k.to_s<<"=").to_sym, v)}
  end
  
  # The method to copy headers from a message.If you provide the particular headers,
  # it will copy only those headers, else will copy all the headers. 
  def copy_from(from_msg, *hdrs)
    @@slog.debug("copy_from: copying headers #{hdrs.join(",")}") if @@slog.debug?
    if hdrs[0] == :_sipper_all
      k = nil
      v = nil
      from_msg.each {|k,v| self[k] = v}
    else
      x = nil
      hdrs.each {|x| self[x] = from_msg[x] if from_msg[x]}
    end
    
    self 
  end
  
  # This method is used to assign arbitrary values to any headers including
  # system headers.The first argument is a symbol indicating the header name
  # and second argument is the value.
  def assign_unparsed(hdr_name, arg)
    unless self.respond_to? hdr_name.to_sym
      self.send((hdr_name.to_s+"=").to_sym, arg) { "do not call" }
    end  
    @headers[hdr_name.to_sym] = if arg.nil?
      nil
    else
      if arg.is_a?(SipHeaders::Header)
        a
      elsif arg.is_a?(Array) 
        a = arg.dup
      else
        a = arg.split(",")
      end
      unless hdr_name.to_s == "content"
        b = a.map do |z| 
          _find_parser_and_parse(hdr_name.to_sym, z, false)
        end                                    # map
      else
        b = a
      end                                      # unless content
      b
    end       
  end
  
  def method_missing(m,*a, &block)
    if (md=(/=$/.match(m.to_s)))
      m_name = md.pre_match
      m_name_plural = m_name+"s"
      Message.class_eval do
      
        define_method(m_name.to_sym) do  # accessor
          if @headers[m_name.to_sym]
           val = @headers[m_name.to_sym][0] || ''
          else
            nil
          end
        end
        
        define_method(m_name_plural.to_sym) do # accessor for mv headers
          @headers[m_name.to_sym]
        end
        
        define_method(("add_"+m_name).to_sym) do |arg|  #append at the end
          (@headers[m_name.to_sym] ||= []) << _find_parser_and_parse(m_name.to_sym, arg, true)
          self
        end
        
        define_method(m) do |arg| #mutator
          s_name = m_name.to_sym
          if @headers[s_name] && 
             @headers[s_name][0].respond_to?(:frozen_str) && 
             @headers[s_name][0].frozen_str
          then
            return @headers[s_name]
          end   
          @headers[s_name] = if arg.nil?
            nil
          else
            if arg.is_a?(SipHeaders::Header)
              a = [arg]
            elsif arg.is_a?(Array) 
              a = arg.dup
            elsif (m_name =~ /authenticat/ || m_name =~ /authorization/)  # auth headers have "," in hdr values
              a = [arg] 
            elsif m_name == "content"
              a = arg.split("\r\n").map { |y| y.strip }
            else
              a = arg.split(",").map { |y| y.strip }
            end
            unless (m_name == "content")
              b = a.map do |z| 
                _find_parser_and_parse(s_name, z, true)
              end                                    # map
            else
              b = a
            end                                      # unless content
            b
          end                                        # assign from if
        end                                          # define_method
        
        define_method(("pop_"+m_name).to_sym) do  #pop top
          if @headers[m_name.to_sym]
            p = @headers[m_name.to_sym].shift 
            if @headers[m_name.to_sym].length == 0
              @headers.delete(m_name.to_sym)    
            end
            return p
          else
            nil
          end
        end
        
        define_method(("push_"+m_name).to_sym) do |arg|  #push top
          if @headers[m_name.to_sym] && (hdr_sz=@headers[m_name.to_sym].size) > 0
            @headers[m_name.to_sym].reverse!  if hdr_sz > 1
            @headers[m_name.to_sym].push(_find_parser_and_parse(m_name.to_sym, arg, true))
            @headers[m_name.to_sym].reverse!
          else
            (@headers[m_name.to_sym] ||= []) << _find_parser_and_parse(m_name.to_sym, arg, true)  
          end
          self
        end
        
      end  #class_eval

      @@slog.info("Adding header #{m}") if @@slog.info?
      unless block_given?
        send(m, *a, &block)
      end
    else
      raise NoMethodError, "#{m}"
    end
  end
 
  def [](hdr)
    @headers[hdr]
  end
  
  def []= (hdr, val)
    self.send((hdr.to_s+"=").to_sym, val)  
  end
  
  def _find_parser_and_parse(hname, val, parse_option)
    SipperUtil.find_parser_and_parse(hname, val, parse_option)
  end
  private :_find_parser_and_parse
    
  
  # This method is to be invoked when the header is created but the content 
  # is not parsed. The string provided in "val" is directly written as the 
  # header content. The consequence is also a by-passing of any validations. 
  def assign_header_without_parse(hdr, val)
    if self.respond_to?(hdr)
      self.send(hdr, val) { false }
    else
      self.method_missing((hdr.to_s+"=").to_sym, val) { false } 
    end
  end
  
  def content_len
    if @headers.has_key? :content
      return @headers[:content].join("\r\n").length+2 # for the last element \r\n which doesnt add in join
    else
      return 0
    end 
  end  
  
  # extracts the from tag from the message without a full parse of the header.
  def from_tag
    self.from.tag
  end
 
  # extracts the to tag from the message without a full parse of the header. 
  def to_tag
    self.to.tag
  end
  
  # takes a full From/To header and just returns the value of the tag
  def tag str
   m = TAGP_C.match(str)
   m = TAGP_E.match(str) unless m
   if m
     return m[2]
   else
     return nil
   end
  end
   
  
  def parse_headers arr
    content_idx = -1
    h = nil
    str_dc = nil
    hn = nil
    arr.each_with_index do |str, idx|
      @@slog.debug("parsing header : "+str) if @@slog.debug?
      if !str || str.strip.length == 0  # \r\n\r\n before content
        content_idx = idx+1
        break  
      end  
      h = str.split(":",2)
      str_dc=h[0].strip.downcase
      #todo think about a lookup at the message level of the 
      #header names and a symbols for fast processing.
      str_dc = SipperUtil::CompactConverter.get_expanded(str_dc) if str_dc.size==1 && SipperUtil::CompactConverter.has_expanded_form?(str_dc)       
      hn = SipperUtil.methodize(str_dc)  # header name
      if @headers[hn.to_sym]
        self.send(("add_"+hn.to_s).to_sym, h[1])
      else
        self.send((hn.to_s+"=").to_sym, h[1])
      end
    end
    @headers[:content_length][0].freeze if @headers[:content_length]
    parse_content arr[content_idx..-1]   if ((content_idx>0) && (content_idx< arr.length))
  end
  
  # Each value in the header hash is an array for MV, content is also a single array.
  # 
  # 18.3 Framing
  # In the case of message-oriented transports (such as UDP), if the message has a 
  # Content-Length header field, the message body is assumed to contain that many bytes.  
  # If there are additional bytes in the transport packet beyond the end of the body, 
  # they MUST be discarded.  If the transport packet ends before the end of the message 
  # body, this is considered an error.  If the message is a   response, it MUST be discarded.  
  # If the message is a request, the element SHOULD generate a 400 (Bad Request) response.  
  # If the message has no Content-Length header field, the message body is assumed to end at 
  # the end of the transport packet.
  # In the case of stream-oriented transports such as TCP, the Content-Length header field 
  # indicates the size of the body. The Content-Length header field MUST be used with 
  # stream oriented transports .
  # 
  def parse_content arr
    # see comment above on framing
    if SipperConfigurator[:ProtocolCompliance]=='strict'
      s = 0
      len = self.content_length.to_s.to_i
      self[:content] = arr.map do |x|
        if s+x.length <= len
          s+=x.length
          x.strip
        else
          ws = x.length - x.strip.length
          en = len-s-ws  # consider white spaces upfront, as we will add \r\n while formatting
          s = len  # to stop loop
          if en>0
            x[0...en].strip
          else
            nil
          end
        end
      end
      self[:content] = self[:content].select {|x| x } # non nil
    else  # lax compliance
      self[:content] = arr.map {|x| x.strip}
    end
    @@slog.warn "Actual content length #{content_len} different from Content-Length header #{content_length}" if content_len != content_length.to_s.to_i && @@slog.warn?
  end
  
  # todo test this feature
  def format_as_separate_headers_for_mv(*hdrs)
    @separate_mv_hdrs ||= []
    @separate_mv_hdrs += hdrs
  end
  
  def header_order=(hoarr)
    @header_order_arr = hoarr
  end
  
  def compact_headers=(charr)
    @compact_headers = charr
  end

  def _header_name(k)
    if @compact_headers && ((@compact_headers.include?(:all_headers)||@compact_headers.include?(k)) && SipperUtil::CompactConverter.has_compact_form?(k))
      SipperUtil::CompactConverter.get_compact(k)
    else
      SipperUtil.headerize(k)
    end
  end
  
  
  # gives the transaction id for the message. If the message is a RFC3261 message 
  # then the branch is taken otherwise it is computed from the message. 
  def txn_id
    #todo check for magic cookie and evaluate the txn_id if the message is 
    #not a 3261 message
    self.via.branch
  end
  
  # Returns the body of the message, which is another name for content but
  # message.content does not return proper contents of the message. Instead
  # message.contents (note the s in the end) returns the contents as an array.
  # This method however returns the properly formatted message body. 
  def body
    b = nil
    if @headers[:content]
      b = ""
      @headers[:content].each {|x| b << x << "\r\n"} 
    end
    b
  end
  
  def sdp=(sdp)
    @sdp = sdp                                 
    if not self.content_type.to_s =~ /multipart/
		sdp_csv_content = @sdp.format_sdp("\r\n")
		self.content = sdp_csv_content
		self.content_type = 'application/sdp'
	end
  end
  
  def multipart_content=(multipart_content)
    @multipart_content = multipart_content
    self.content_type = "multipart/" + multipart_content.subtype 
    self.content_type.boundary = multipart_content.boundary
    self.content = multipart_content.to_s
  end  
  
  # takes [body] and type as two arguments
  def set_body(b, type)
    self.content = b.join("\r\n")
    self.content_type = type
  end
  
  def _format_message(smsg)    
    if @header_order_arr
      ordered_headers = @header_order_arr + (@headers.keys - @header_order_arr)
    else
      ordered_headers = @headers.keys
    end
    ordered_headers.each do |k|
      next if k == :content
      v = @headers[k]
      next if v.nil?  # nil valued headers are hidden and popped headers leave [] 
      if @separate_mv_hdrs && @separate_mv_hdrs.include?(k)
        v.each {|val| smsg << _header_name(k) << ":" << " " << val.to_s << "\r\n" }
      else
        smsg << _header_name(k) << ":" << " " << (v.map {|val| val.to_s}).join(", ") << "\r\n" 
      end
    end  
    
    smsg << "\r\n"
    if ((_cl=content_len) > 0)
      smsg << self.body
    end
    smsg
  end
 
  def short_to_s
    if is_request?
      self.method
    elsif is_response?
      self.code.to_s
    end
  end
  
  def update_content_length
    self.content_length = self.content_len.to_s unless self.respond_to?(:content_length) && self.content_length && self.content_length.respond_to?(:frozen_str) && self.content_length.frozen_str
  end

   private :tag, :_header_name
   protected :_format_message
   
end

unless defined? PRIMED
  addr = "sip:nasir@sipper.com"
  f = "foo"
  m = Message.new
  m.accept = f
  m.accept_contact = f
  m.accept_encoding = f
  m.accept_language = f
  m.allow = f
  m.authentication_info = 'nextnonce="d", qop=auth, nc=00000001, cnonce="0", rspauth="6"'
  m.authorization = 'Digest username="b", realm="b.com", nonce="d", uri="sip:b@b.c", qop=auth, nc=00000001, cnonce="0", response="6", opaque="5"'
  m.call_id = f
  m.call_info = f
  m.contact = addr
  m.content_disposition = f
  m.content_encoding = f
  m.content_language = f
  m.content_length = "1"              
  m.content_type = f                
  m.cseq = "1"                          
  m.date = f                                 
  m.error_info = f                    
  m.event = f                      
  m.expires = "1"                       
  m.from = addr                        
  m.hide = f                         
  m.history_info = f                
  m.identity = f            
  m.identity_info = f       
  m.in_reply_to = f                   
  m.join = f                        
  m.max_forwards = "1"                  
  m.mime_version = f                  
  m.min_expires = "1"                   
  m.min_se = "1"                        
  m.organization = f                                       
  m.p_asserted_identity = addr            
  m.p_charging_vector = f             
  m.p_visited_network_id = f        
  m.path = addr                         
  m.priority = "1"                      
  m.privacy = f                       
  m.proxy_authenticate = 'Digest realm="a.c", domain="sip:s.c", nonce="f", stale=FALSE, algorithm=MD5'            
  m.proxy_authorization = 'Digest username="b", realm="b.com", nonce="d", uri="sip:b@b.c", qop=auth, nc=00000001, cnonce="0", response="6", opaque="5"'        
  m.proxy_require = f                 
  m.rack = f                        
  m.reason = f                        
  m.record_route = addr                  
  m.refer_sub = "false"                     
  m.refer_to = addr               
  m.referred_by = addr            
  m.reject_contact = f         
  m.replaces = f                      
  m.reply_to = addr                      
  m.request_disposition = f  
  m.require = f                       
  m.retry_after = "1"                   
  m.route = addr                         
  m.rseq = "1"                          
  m.server = f                        
  m.service_route = addr                
  m.session_expires = f                     
  m.subject = f                  
  m.subscription_state = f         
  m.supported = f                   
  m.target_dialog = f                
  m.timestamp = f                     
  m.to = addr                                        
  m.unsupported = f                   
  m.user_agent = f                    
  m.via = "SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0"                 
  m.warning = f                       
  m.www_authenticate = 'Digest realm="a.c", domain="sip:s.c", nonce="f", stale=FALSE, algorithm=MD5'  
  PRIMED = true
end
