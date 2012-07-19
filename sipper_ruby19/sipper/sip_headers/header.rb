require 'util/sipper_util'
require 'ruby_ext/object'
require 'facets/core/hash/reverse_merge'
require 'sip_logger'
require 'ruby_ext/mutable_class'
require 'sip_headers/sipuri'

module SipHeaders
  
  # Base Header class
  class Header
    include SipLogger
    # name is set in Message
    attr_accessor :name
    attr_accessor :frozen_str, :header_value, :header_params, :default_parse
    protected :header_value, :header_params, :default_parse
    
    alias_method :old_dup, :dup
    
    ASSIGN = /=$/.freeze
    
    def initialize
      @ilog = logger
    end

    def dup
      obj = self.old_dup  
      obj.frozen_str = self.frozen_str.dup 
      obj.header_value = self.header_value.dup 
      obj.header_params = self.header_params.dup  
      obj.default_parse = self.default_parse.dup 
      obj
    end
    
    
    def to_s
      if @frozen_str
        @frozen_str
      else
        _format
      end
    end 
    
    def to_str
      to_s
    end
    
    def freeze
      @frozen_str = _format unless @frozen_str
      super
    end
    
    def ==(other)
      return true if self.object_id==other.object_id 
      self.to_s == other.to_s
    end
    
    # Returns the complete formatted header
    # this is the default format method.
    def _format
      return nil unless self.header_value  
      str = self.header_value.dup
      k = nil
      v = nil
      if self.header_params
        self.header_params.each do |k,v|
          if v
            if v == ""
              str << ";" << k 
            else
              str << ";" << k << "=" << v.to_s 
            end
          end
        end
      end
      str
    end
    private :_format
    
    
    # returns just the value of the header, sans params
    def header_value
      @header_value
    end
    
    # returns a hash of parameters
    def header_params
      @header_params
    end
    
    def cache_and_clear(val_str, iv_arr)
      @frozen_str = val_str
      @header_params = {}
      clear_ivs(iv_arr)
    end
    protected :cache_and_clear
    
    def assign(val_str, parse=true)
      @default_parse = true
      unless parse
        cache_and_clear(val_str, [:@header_value])
      else
        @frozen_str = nil
        @header_value, @header_params = SipperUtil.parameterize_header(val_str)
      end 
      self
    end
    
    def default_parse?
      @default_parse
    end
    
    def method_missing(m, *a)
      if (md=(ASSIGN.match(m.to_s)))
        name = md.pre_match
      else
        name = m.to_s
      end
      meta = class << self; self; end
      meta.send(:define_method, name) { self.header_params[name] }
      x = nil
      meta.send(:define_method, :"#{name}=") { |x| self.header_params[name] = x }
      self.send m, *a
    rescue => e
      @ilog.error(e.backtrace.join("\n")) if @ilog.error?
    end
    
    def [](param)
      @header_params[param.to_s]
    end
    
    def []= (param, val)
      @header_params[param.to_s] = val
    end
    
    def has_param?(key)
      @header_params.has_key?(key.to_s)
    end
    
    
    # for logging
    def classname
      "sipheaders_header"
    end
    
  end  #Header Class
  
  # To implement a new header have a method 
  # - assign() which parses the val_str, have 
  # - header_value() that returns a formatted value of the header without any params
  # - in addition to have any specfic attribute accessor special to the header.
  
  
  #  Via class
  #  ---------
  #  Via               =  ( "Via" / "v" ) HCOLON via-parm *(COMMA via-parm)
  #  via-parm          =  sent-protocol LWS sent-by *( SEMI via-params )
  #  via-params        =  via-ttl / via-maddr
  #                       / via-received / via-branch
  #                       / via-extension
  #  via-ttl           =  "ttl" EQUAL ttl
  #  via-maddr         =  "maddr" EQUAL host
  #  via-received      =  "received" EQUAL (IPv4address / IPv6address)
  #  via-branch        =  "branch" EQUAL token
  #  via-extension     =  generic-param
  #  sent-protocol     =  protocol-name SLASH protocol-version
  #                       SLASH transport
  #  protocol-name     =  "SIP" / token
  #  protocol-version  =  token
  #  transport         =  "UDP" / "TCP" / "TLS" / "SCTP"
  #                       / other-transport
  #  sent-by           =  host [ COLON port ]
  #  ttl               =  1*3DIGIT ; 0 to 255
  #  -----------
  #  Example  -  Via: SIP/2.0/UDP 172.17.31.207:6062;branch=z9hG4bK-1-0
  
  class Via < Header
    
    attr_accessor :protocol, :version, :transport, :sent_by_ip, :sent_by_port
    
    PROTO_REGX        = /(.+?)\/(.+?)\/(.+)$/
    SENT_WPORT_REGX   = /(.+?):(.+?);/
    SENT_WOPORT_REGX  = /(.+?);/
    
    def initialize
      @name = "Via"
      super
    end
    
     def dup
      obj = super
      obj.protocol = self.protocol.dup
      obj.version  = self.version.dup
      obj.transport = self.transport.dup
      obj.sent_by_ip = self.sent_by_ip.dup
      obj.sent_by_port = self.sent_by_port.dup
      obj
    end
    
    def header_value
      return nil unless @protocol
      str = sprintf("%s/%s/%s %s", @protocol, @version, @transport, @sent_by_ip)
      str << ":" << @sent_by_port if @sent_by_port 
      str
    end
    
    
    def assign(val_str, parse=true)
      unless parse
        cache_and_clear(val_str, 
                        [:@protocol, :@version, :@transport, :@sent_by_ip, :@sent_by_port])
      else
        @frozen_str = nil
        sent_protocol, sent_by_plus = val_str.split(" ")
        m = PROTO_REGX.match(sent_protocol.strip)
        @protocol = m[1] 
        @version = m[2] 
        @transport = m[3] 
        m = SENT_WPORT_REGX.match(sent_by_plus.strip)
        if m
          @sent_by_ip = m[1] 
          @sent_by_port = m[2] 
        else
          m = SENT_WOPORT_REGX.match(sent_by_plus.strip)
          if m
            @sent_by_ip = m[1]  
          end
        end
        @header_params = SipperUtil.parameterize_header(val_str)[1]
      end  # parse or do not parse
      self 
    end    # assign method
  end      # via class
  
  
  # Address header like To, From, Contact, Reply-To etc. 
  # 
  # To header 
  # ---------
  # To        =  ( "To" / "t" ) HCOLON ( name-addr
  #           / addr-spec ) *( SEMI to-param )
  #           to-param  =  tag-param / generic-param
  # name-addr      =  [ display-name ] LAQUOT addr-spec RAQUOT
  # addr-spec      =  SIP-URI / SIPS-URI / absoluteURI
  # 
  # --------------
  # Example
  # To: Bob <sip:bob@biloxi.com>;tag=a6c85cf     
  #     
  class AddressHeader < Header
    attr_accessor :display_name, :uri
    attr_accessor :only_addr_spec
    protected :only_addr_spec
    
    DISPLAY_NAME_REGX = /[[:print:]]*?</
    URI_EXTRACT_REGX  = /<.+?>/
    
    def dup
      obj = super
      obj.display_name = self.display_name.dup
      obj.uri  = self.uri.dup
      obj.only_addr_spec = self.only_addr_spec.dup
      obj
    end
    
    def header_value
      return nil unless @uri
      if @display_name && @display_name.length>0
        sprintf("%s <%s>", @display_name, @uri.to_s) 
      else
        sprintf("<%s>", @uri.to_s)
      end
    end
    
    
    def assign(val_str, parse=true)
      unless parse
        cache_and_clear(val_str, 
                        [:@display_name, :@uri ])
      else  
        @frozen_str = nil      
        m = DISPLAY_NAME_REGX.match(val_str)
        if m
          @display_name = m[0][0...-1].strip  if m[0].length > 1
        else
          @display_name = ""
        end
        @uri, remainder = _extract_uri(val_str) 
        if remainder
          @header_params = SipperUtil.parameterize_header(remainder)[1]
        else
          @header_params = {}
        end
      end  # parse or assign
      self 
    end    # assign method
    
    def _extract_uri(str)
      if m = URI_EXTRACT_REGX.match(str)
        #[m[0][1...-1], m.post_match]
        [URI::SipUri.new.assign(m[0][1...-1]), m.post_match] 
      else
        @only_addr_spec = true
        # To address the following case where <> may not be 
        # there for addr-spec
        # To        =  ( "To" / "t" ) HCOLON ( name-addr
        # / addr-spec ) *( SEMI to-param )
        s = str.split(";")
	      s[1]= ";"+s[1] if s[1] != nil
        [URI::SipUri.new.assign(s[0]), s[1]] 
      end   
    end
    
    private :_extract_uri
    
  end
  
  class To < AddressHeader
    def initialize
      @name = "To"
      super
    end
  end
  
  class From < AddressHeader
    def initialize
      @name = "From"
      super
    end
  end
  
  
  class Route < AddressHeader
    def initialize
      @name = "Route"
      super
    end
  end
  
  class RecordRoute < AddressHeader
    def initialize
      @name = "Record-Route"
      super
    end
  end
  
  class ReferTo < AddressHeader
    def initialize
      @name = "Refer-To"
      super
    end
  end
  
  
  
  class Contact < AddressHeader
    
    def initialize
      @name = "Contact"
      super
    end
    
    def header_value
      return nil unless @uri
      if @display_name && @display_name.length>0
        sprintf("%s <%s>", @display_name, @uri.to_s) 
      else
        if @uri.to_s == "*"
          "*"
        else 
          sprintf("<%s>", @uri.to_s)
        end
      end
    end
  end
  
  class PAssociatedUri < AddressHeader
    
    def initialize
      @name = "P-Associated-URI"
      super
    end
    
  end

  class PCalledPartyId < AddressHeader
    
    def initialize
      @name = "P-Called-Party-ID"
      super
    end
    
  end  
  
  class PAssertedIdentity < AddressHeader
    
    def initialize
      @name = "P-Asserted-Identity"
      super
    end
    
  end
  
  class Path < AddressHeader
    def initialize
      @name = "Path"
      super
    end
  end
  
  class ServiceRoute < AddressHeader
    def initialize
      @name = "Service-Route"
      super
    end
  end  
  
  
  # From RFC 3326
  #Reason = "Reason" HCOLON reason-value *(COMMA reason-value)
  #reason-value = protocol *(SEMI reason-params)
  #protocol = "SIP" / "Q.850" / token
  #reason-params = protocol-cause / reason-text / reason-extension
  #protocol-cause = "cause" EQUAL cause
  #cause = 1*DIGIT
  #reason-text = "text" EQUAL quoted-string
  #reason-extension = generic-param
  #  
  #Examples:
  #Reason: SIP ;cause=200 ;text="Call completed elsewhere"
  #Reason: Q.850 ;cause=16 ;text="Terminated"
  #Reason: SIP ;cause=600 ;text="Busy Everywhere"
  #Reason: SIP ;cause=580 ;text="Precondition Failure"

  class Reason < Header
    attr_accessor :protocol, :cause, :text
    
    def initialize
      @name = "Reason"
      super
    end

    def dup
      obj = super
      obj.protocol = self.protocol.dup
      obj.cause  = self.cause.dup
      obj.text = self.text.dup
      obj
    end
    
    def header_value
      return nil unless self.protocol
      str = sprintf("%s", self.protocol)
      str << ";cause=" << self.cause if self.cause
      str << ";text=" <<  self.text if self.text
      str
    end
    
    def assign(val_str, parse=true)
      unless parse
        cache_and_clear(val_str, 
                        [:@protocol, :@cause, :@text])
      else
        @frozen_str = nil
        @protocol, remainder = val_str.split(";", 2)
        remainder.split(";").each do |x|
          k, v = x.split("=", 2)   
          self.send((k.strip+"=").to_sym, v.strip)
        end
      end  
      self 
    end    # assign method
          
  end #class  
  
  # From RFC 2617
  # challenge = "Digest" digest-challenge
  # digest-challenge = 1#( realm | [ domain ] | nonce |
  #[ opaque ] |[ stale ] | [ algorithm ] |
  #[ qop-options ] | [auth-param] )
  #domain = "domain" "=" <"> URI ( 1*SP URI ) <">
  #URI = absoluteURI | abs_path
  #nonce = "nonce" "=" nonce-value
  #nonce-value = quoted-string  
  #opaque = "opaque" "=" quoted-string
  #stale = "stale" "=" ( "true" | "false" )
  #algorithm = "algorithm" "=" ( "MD5" | "MD5-sess" |
  #token )
  #qop-options = "qop" "=" <"> 1#qop-value <">
  #qop-value = "auth" | "auth-int" | token
  #
  # Example --
  # WWW-Authenticate: Digest realm="atlanta.com",
  # domain="sip:boxesbybob.com", qop="auth",
  # nonce="f84f1cec41e6cbe5aea9c8e88d359",
  # opaque="", stale=FALSE, algorithm=MD5
  # ------
  # Example --
  # Proxy-Authenticate: Digest realm="atlanta.com",
  # domain="sip:ss1.carrier.com", qop="auth",
  # nonce="f84f1cec41e6cbe5aea9c8e88d359",
  # opaque="", stale=FALSE, algorithm=MD5
  
  class Authenticate < Header
    attr_accessor :scheme, :realm, :domain, :nonce, :opaque, :stale, :algorithm,
    :qop
    
    def initialize
      @name = "Authenticate"
      super
    end
    
     def dup
      obj = super
      obj.scheme = self.scheme.dup
      obj.realm  = self.realm.dup
      obj.domain = self.domain.dup
      obj.nonce = self.nonce.dup
      obj.opaque = self.opaque.dup
      obj.stale = self.stale.dup
      obj.algorithm = self.algorithm.dup
      obj.qop = self.qop.dup
      obj
    end
    
    def header_value
      return nil unless self.realm
      str = sprintf("%s realm=%s", @scheme, self.realm)
      str << ", domain=" << self.domain if self.domain
      str << ", qop=" << self.qop if self.qop
      str << ", nonce=" << self.nonce if self.nonce
      str << ", opaque=" << self.opaque if self.opaque
      str << ", stale=" << self.stale.to_s.upcase if self.stale
      str << ", algorithm=" << self.algorithm if self.algorithm
      str
    end
    
    
    def assign(val_str, parse=true)
      unless parse
        cache_and_clear(val_str, 
                        [:realm, :domain, :nonce, :opaque, :stale, :algorithm, :qop])
      else  
        @frozen_str = nil      
        @scheme, challenge = val_str.split(" ", 2)
        challenge.split(",").each do |x|
          k, v = x.split("=", 2)   
          self.send((k.strip+"=").to_sym, v.strip)
        end
        @header_params = {}
        
      end  # parse or assign
      self 
    end    # assign method
  end
  
  # -- See SipperUtil.classify
  # ++
  class  WwwAuthenticate < Authenticate
    def initialize
      @name = "WWW-Authenticate"
      super
    end
  end
  
  class ProxyAuthenticate < Authenticate  
    
    def initialize
      @name = "Proxy-Authenticate"
      super
    end
    
  end
  
  
  # Authorization header
  # credentials = "Digest" digest-response
  # digest-response = 1#( username | realm | nonce | digest-uri
  # | response | [ algorithm ] | [cnonce] |
  # [opaque] | [message-qop] |
  # [nonce-count] | [auth-param] )
  # username = "username" "=" username-value
  # username-value = quoted-string
  # digest-uri = "uri" "=" digest-uri-value
  # digest-uri-value = request-uri ; As specified by HTTP/1.1
  # message-qop = "qop" "=" qop-value
  # cnonce = "cnonce" "=" cnonce-value
  # cnonce-value = nonce-value
  # nonce-count = "nc" "=" nc-value
  # nc-value = 8LHEX
  # response = "response" "=" request-digest
  # request-digest = <"> 32LHEX <">
  # LHEX = "0" | "1" | "2" | "3" |
  # "4" | "5" | "6" | "7" |
  # "8" | "9" | "a" | "b" |
  # "c" | "d" | "e" | "f"
  #
  # Example -------------------
  # Authorization: Digest username="bob",
  # realm="biloxi.com",
  # nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093",
  # uri="sip:bob@biloxi.com",
  # qop=auth,
  # nc=00000001,
  # cnonce="0a4f113b",
  # response="6629fae49393a05397450978507c4ef1",
  # opaque="5ccc069c403ebaf9f0171e9517f40e41"
  # ------------------------------
  class Authorization < Header
    attr_accessor :scheme, :username, :realm, :nonce, :uri, :nc, :opaque, :algorithm,
    :qop, :cnonce, :response
    
    def initialize
      @name = "Authorization"
      super
    end
    
    def dup
      obj = super
      obj.scheme = self.scheme.dup
      obj.username = self.username.dup
      obj.realm  = self.realm.dup
      obj.nonce = self.nonce.dup
      obj.uri = self.uri.dup
      obj.nc = self.nc.dup
      obj.opaque = self.opaque.dup
      obj.algorithm = self.algorithm.dup
      obj.qop = self.qop.dup
      obj.cnonce = self.cnonce.dup
      obj.response = self.response.dup
      obj
    end
    
    def header_value
      return nil unless self.username
      str = sprintf("%s username=%s", @scheme, self.username)
      str << ", realm=" << self.realm if self.realm
      str << ", nonce=" << self.nonce if self.nonce
      str << ", uri=" << self.uri.to_s if self.uri.to_s
      str << ", qop=" << self.qop if self.qop
      str << ", nc=" << self.nc if self.nc
      str << ", cnonce=" << self.cnonce if self.cnonce
      str << ", response=" << self.response if self.response
      str << ", opaque=" << self.opaque if self.opaque
      str << ", algorithm=" << self.algorithm if self.algorithm
      str
    end
    
    
    def assign(val_str, parse=true)
      unless parse
        cache_and_clear(val_str, 
                        [:realm, :username, :nonce, :uri, :nc, :opaque, :algorithm, :qop, :cnonce, :response])
      else  
        @frozen_str = nil      
        @scheme, rest = val_str.split(" ", 2)
        rest.split(",").each do |x|
          k, v = x.split("=", 2)  
          if k =~ /uri/
            self.send((k.strip+"=").to_sym, URI::SipUri.new.assign(v.strip))  
          else
            self.send((k.strip+"=").to_sym, v.strip)
          end  
        end
        @header_params = {}
      end  # parse or assign
      self 
    end    # assign method
    
  end
  
  class ProxyAuthorization < Authorization 
    def initialize
      @name = "Proxy-Authorization"
      super
    end
  end
  
  # AuthenticationInfo = "Authentication-Info" ":" auth-info
  # auth-info = 1#(nextnonce | [ message-qop ]
  # | [ response-auth ] | [ cnonce ]
  # | [nonce-count] )
  # nextnonce = "nextnonce" "=" nonce-value
  # response-auth = "rspauth" "=" response-digest
  # response-digest = <"> *LHEX <">
  # example Authentication-Info: nextnonce="47364c23432d2e131a5fb210812c"
  class AuthenticationInfo < Header
    attr_accessor :nextnonce, :nc, :rspauth, :qop, :cnonce
    
    def initialize
      @name = "Authentication-Info"
      super
    end
    def dup
      obj = super
      obj.nextnonce = self.nextnonce.dup
      obj.nc = self.nc.dup
      obj.rspauth = self.rspauth.dup
      obj.qop = self.qop.dup
      obj.cnonce = self.cnonce.dup
      obj
    end
    
    def header_value
      return nil unless self.nextnonce
      str = ""
      str << "nextnonce=" << self.nextnonce if self.nextnonce
      str << ", qop=" << self.qop if self.qop
      str << ", nc=" << self.nc if self.nc
      str << ", cnonce=" << self.cnonce if self.cnonce
      str << ", response=" << self.response if self.response
      str << ", rspauth=" << self.rspauth if self.rspauth
      str
    end
    
    
    def assign(val_str, parse=true)
      unless parse
        cache_and_clear(val_str, 
                        [:nextnonce, :nc, :rspauth, :qop, :cnonce])
      else  
        @frozen_str = nil      
        val_str.split(",").each do |x|
          k, v = x.split("=", 2)   
          self.send((k.strip+"=").to_sym, v.strip)
        end
        @header_params = {}
      end  # parse or assign
      self 
    end    # assign method
    
  end # auth info header
  
end   # module
