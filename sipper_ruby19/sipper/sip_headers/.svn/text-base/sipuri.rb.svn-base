
=begin
SIP-URI          =  "sip:" [ userinfo ] hostport
                    uri-parameters [ headers ]
SIPS-URI         =  "sips:" [ userinfo ] hostport
                    uri-parameters [ headers ]
userinfo         =  ( user / telephone-subscriber ) [ ":" password ] "@"
user             =  1*( unreserved / escaped / user-unreserved )
user-unreserved  =  "&" / "=" / "+" / "$" / "," / ";" / "?" / "/"
password         =  *( unreserved / escaped /
                    "&" / "=" / "+" / "$" / "," )
hostport         =  host [ ":" port ]
host             =  hostname / IPv4address / IPv6reference
hostname         =  *( domainlabel "." ) toplabel [ "." ]
domainlabel      =  alphanum
                    / alphanum *( alphanum / "-" ) alphanum
toplabel         =  ALPHA / ALPHA *( alphanum / "-" ) alphanum
IPv4address    =  1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT "." 1*3DIGIT
IPv6reference  =  "[" IPv6address "]"
IPv6address    =  hexpart [ ":" IPv4address ]
hexpart        =  hexseq / hexseq "::" [ hexseq ] / "::" [ hexseq ]
hexseq         =  hex4 *( ":" hex4)
hex4           =  1*4HEXDIG
port           =  1*DIGIT

The BNF for telephone-subscriber can be found in RFC 2806 [9].  Note, however, that 
any characters allowed there that are not allowed in the user part of the SIP URI MUST be escaped.

uri-parameters    =  *( ";" uri-parameter)
uri-parameter     =  transport-param / user-param / method-param
                     / ttl-param / maddr-param / lr-param / other-param
transport-param   =  "transport="
                     ( "udp" / "tcp" / "sctp" / "tls"
                     / other-transport)
other-transport   =  token
user-param        =  "user=" ( "phone" / "ip" / other-user)
other-user        =  token
method-param      =  "method=" Method
ttl-param         =  "ttl=" ttl
maddr-param       =  "maddr=" host
lr-param          =  "lr"
other-param       =  pname [ "=" pvalue ]
pname             =  1*paramchar
pvalue            =  1*paramchar
paramchar         =  param-unreserved / unreserved / escaped
param-unreserved  =  "[" / "]" / "/" / ":" / "&" / "+" / "$"

headers         =  "?" header *( "&" header )
header          =  hname "=" hvalue
hname           =  1*( hnv-unreserved / unreserved / escaped )
hvalue          =  *( hnv-unreserved / unreserved / escaped )
hnv-unreserved  =  "[" / "]" / "/" / "?" / ":" / "+" / "$"

=end

# General form sip:user:password@host:port;uri-parameters?headers
# user:password = userinfo component
# 

require 'uri'
require 'util/sipper_util'
require 'ruby_ext/object'
require 'facets/core/hash/reverse_merge'
require 'sip_logger'
require 'ruby_ext/mutable_class'
require 'cgi'

module URI                   
  
  class SipUri
    include SipLogger
    
    attr_accessor  :proto, :user, :password, :host, :port, 
    :uri_params, :headers, :frozen_str
    
    
    alias_method :old_dup, :dup
    
    ASSIGN = /=$/.freeze
    
    COLON = /:/.freeze
    SCOLON = /;/.freeze
    AMP = /&/.freeze
    QUES = /\?/.freeze
    AT = /@/.freeze
    EQL = /=/.freeze
    DQ = /\"/.freeze
    
    def dup
      obj = self.old_dup  
      obj.frozen_str = self.frozen_str.dup 
      obj.proto = self.proto.dup 
      obj.user = self.user.dup
      obj.password = self.password.dup
      obj.host = self.host.dup
      obj.port = self.port.dup
      obj.uri_params = self.uri_params.dup
      obj.headers = self.headers.dup
      obj
    end
    
    def ==(other)
      return true if self.object_id==other.object_id   
      self.to_s == other.to_s
    end
    
    def port=(p)
      @port = p.to_s unless p.nil?
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
      self.to_s == other.to_s
    end
    
    # Returns the complete formatted URI
    # this is the default format method.
    # sip:user:password@host:port;uri-parameters?headers
    def _format
      return nil unless self.host  
      str = self.proto.dup
      str << ":"
      str << self.user if self.user
      if self.user && self.password
        str << ":"
        str << self.password
      end  
      str << "@" if self.user
      str << self.host
      if self.port
        str << ":"
        str << self.port.to_s
      end
      if self.uri_params
        k = nil
        v = nil
        self.uri_params.each do |k,v|
          if v
            if v == ""
              str << ";" << k 
            else
              str << ";" << k << "=" << v 
            end
          end
        end
      end
      
      if self.headers
        first = true
        k = nil
        v = nil
        self.headers.each do |k,v|
          if v
            if v == ""
              if first
                str << "?" << k
                first = false
              else
                str << "&" << k
              end
            else
              if first
                str << "?" << SipperUtil.headerize(k) << "=" <<  CGI.escape(v.to_s) 
                first = false
              else
                str << "&" << SipperUtil.headerize(k) << "=" << CGI.escape(v.to_s)
              end              
            end
          end
        end
      end
      str
    end
    private :_format
    
    
    
    def cache_and_clear(val_str, iv_arr)
      @frozen_str = val_str
      @headers = {}
      @uri_params = {}
      clear_ivs(iv_arr)
    end
    protected :cache_and_clear
    
    #  sip:user:password@host:port;uri-parameters?headers
    def assign(val_str, parse=true)
      return nil unless val_str
      if (!parse || val_str=="*")
        cache_and_clear(val_str, [:@proto, :@user, :@password, :@host, :@port])
      else
        @frozen_str = nil
        str = val_str
        @headers = {}
        @uri_params = {}
        hsa = str.split(QUES)  # done to avoid a COLON appearing in a header
        _extract_headers(hsa[1]) if hsa.length > 1
        csa = hsa[0].split(COLON) #colon separated array
        
        
        case csa.length
          # sip:host;uri-parameters
          # sip:user@host;uri-parameters
        when 2     
          @proto = csa[0] 
          if idx=csa[1].index(SCOLON)
            if aidx=csa[1].index(AT)
              @user = csa[1][0...aidx]
              @host = csa[1][aidx+1...idx]
            else
              @host = csa[1][0...idx]
            end  
            _extract_params(csa[1])
          else
            if aidx=csa[1].index(AT)
              @user = csa[1][0...aidx]
              @host = csa[1][aidx+1..-1]
            else
              @host = csa[1]
            end
          end
          
          # <1> sip:user@host:port;uri-parameters  
          # or <2> sip:user:password@host;uri-parameters
          # or <3> sip:host:port;uri-parameters
        when 3     
          @proto = csa[0]
          if idx=csa[1].index(AT) #first form
            @user = csa[1][0...idx]
            @host = csa[1][idx+1..-1]
            if idx=csa[2].index(SCOLON)
              @port = csa[2][0...idx]
              _extract_params(csa[2])
            else
              @port = csa[2]
            end
          elsif  idx=csa[2].index(AT) #second form
            @user = csa[1]
            asa = csa[2].split(AT)
            @password = asa[0]
            if idx=asa[1].index(SCOLON)
              @host = asa[1][0...idx]
              _extract_params(asa[1])
            else
              @host = asa[1]
            end
          else  #third form
            @host = csa[1]
            if idx=csa[2].index(SCOLON)
              @port = csa[2][0...idx]
              _extract_params(csa[2])
            else
              @port = csa[2]
            end
          end
          
          #  sip:user:password@host:port;uri-parameters?headers  
        when 4
          @proto = csa[0]
          @user = csa[1]
          asa = csa[2].split(AT)
          @password = asa[0]
          @host = asa[1]
          if idx=csa[3].index(SCOLON)
            @port = csa[3][0...idx]
            _extract_params(csa[3])
          end    
        end  
      end 
      self
    end
    
    
    # out of xyz;uri-parameters?headers
    # takes xyz;uri-parameters
    def _extract_params(str)
      @uri_params = SipperUtil.parameterize_header(str)[1]    
    end
    private :_extract_params
    
    # out of xyz;uri-parameters?headers
    # takes 'headers'
    def _extract_headers(str)
      
      asa = str.split(AMP)
      @headers = {}
      esa = nil
      hv = nil
      asa.each do |hdr|
        esa = hdr.split(EQL)
        hname = SipperUtil.methodize(esa[0])
        if esa[1]
          
          if esa[1] =~ DQ
            hv = esa[1][1...-1]
          else
            hv = esa[1]
          end
          hv = CGI.unescape(hv)
          @headers[hname] = SipperUtil.find_parser_and_parse(hname, hv, true)
        end  
      end  
    end
    private :_extract_headers
    
    
    
    def get_param(param)
      @uri_params[param.to_s]  
    end
    
    def add_param(param, val)
      @uri_params[param.to_s] = val
    end
    
    def has_param?(key)
      @uri_params.has_key?(key.to_s)
    end
    
    def remove_param(param)
      @uri_params.delete(param.to_s)  
    end
    
    
    
    def get_header(hdr)
      @headers[SipperUtil.methodize(hdr)]  
    end
    
    def add_header(hdr, val)
      hname = SipperUtil.methodize(hdr)
      @headers[hname] = SipperUtil.find_parser_and_parse(hname, val, true)
    end
    
    def has_header?(key)
      @headers.has_key?(SipperUtil.methodize(key))
    end
    
    def remove_header(hdr)
      @headers.delete(SipperUtil.methodize(hdr))  
    end
    
    
  end
  
end  
