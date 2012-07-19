require 'sip_headers/header'
require 'sip_logger'
require 'strscan'
require 'facets/core/string/underscore'

module SipperUtil
  include SipLogger

  RCOLON = /: /
  SCOLON = /;/
  NUMERIC_CSEQ = /\d+\s?/
  SUCC_RANGE = 200..299
  RPROV_RANGE = 101..199
  BOOL_MAP = { :true=>true, :false=>false }
  
  def log_and_raise(err_msg, ex=RuntimeError)
    loge(err_msg) 
    raise ex, err_msg
  end
  
  def SipperUtil.trand
    ((Time.now.usec)/1000).to_s + rand(10000).to_s 
  end
  
  # Converts the given file name into a well formed 
  # classname. Assumes that file names are underscore 
  # separated and class names are camel case  
  # -4 to remove .rb
  # 
  def SipperUtil.classify(fname)
    x = nil
    if fname =~ /\.rb$/
       fname[0..-4].split("_").map{|x| x.capitalize}.join
    else
       fname.split("_").map{|x| x.capitalize}.join
    end
  end
  
  # does reverse of classify, i.e generates a filename compliant with
  # Ruby conventions from a class name. 
  def SipperUtil.filify(cname)
    cname.underscore + ".rb"  # from facets
  end
  
  
  # Taken from Rails. This converts a fqcname string to a class constant.
  def SipperUtil.constantize(camel_cased_word)
    unless /^(::)?([A-Z]\w*)(::[A-Z]\w*)*$/ =~ camel_cased_word
      raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
    end
    camel_cased_word = "::#{camel_cased_word}" unless $1
    Object.module_eval(camel_cased_word, __FILE__, __LINE__)
  end


  # converts the header names like p_asserted_identity to
  # P-Asserted_Identity. 
  # -- Here is an ugly handling for WWW-Authenticate header todo fix this
  # and also Call-ID handling, as Call-Id is valid yet some tools such
  # as sipp does not handle it.
  # Headers SIP-ETag & SIP-If-Match are added as per rfc 3903
  # Headers P-Associated-URI, P-Called-Party-ID & P-Visited-Network-ID are added as per rfc 3455
  # ++
  def SipperUtil.headerize(hname)
    return nil if hname.nil?
    arr = hname.to_s.split('_')
    i = nil
    arr.each do |i|
      if i.downcase === "www"
        i.upcase!
      else
        i.capitalize!
      end 
    end
    hdr = arr.join('-')
    hdr = "Call-ID" if hdr == "Call-Id"
    # Handling of new headers of rfc 3903
    hdr = "SIP-ETag" if hdr == "Sip-Etag"
    hdr = "SIP-If-Match" if hdr == "Sip-If-Match"
    hdr = "P-Associated-URI" if hdr == "P-Associated-Uri"
    hdr = "P-Called-Party-ID" if hdr == "P-Called-Party-Id"
    hdr = "P-Visited-Network-ID" if hdr == "P-Visited-Network-Id"
    hdr
  end
  
  # Reverse of headerize.
  # P-Asserted_Identity => p_asserted_identity
  def SipperUtil.methodize(hdr)
    return nil if hdr.nil?
    arr = hdr.to_s.downcase.split('-')
    arr.join('_')
  end
  
  # Simply takes the "Header: xxx" and returns "xxx"
  def SipperUtil.header_value(hdr_string)
    m = RCOLON.match(hdr_string)
    m ? m.post_match.strip : hdr_string
  end
  
  # Separates the header and params and returns them in 
  # an array.
  def SipperUtil.header_value_separate_parameters(hdr_string)
    hdr = SipperUtil.header_value(hdr_string)
    m = SCOLON.match(hdr)
    m ? [m.pre_match.strip,  m.post_match.strip] : [hdr, nil]
  end
  
  # If there are parameters then returns them in a hash with header value.
  # Takes full header and also just separated params and returns
  # the array with header value and params hash. 
  # with "My-Header: myvalue" returns ["myvalue", {}]
  # with "My-Header: myvalue;a=1;b=2" returns ["myvalue", {"a"=>"1", "b"=>"2"}]
  # with "a=1;b=2" returns [nil, {"a"=>"1", "b"=>"2"}]
  def SipperUtil.parameterize_header(hdr_string)
    p_hash = {}
    p = SipperUtil.header_value_separate_parameters(hdr_string)
    params = p[1]
    a = nil
    key = nil
    val = nil
    if params
      x = nil
      params.split(";").each do |x|
        a = x.split("=")
        key = a.shift
        val = a.shift
        if key
          val = "" unless val
          p_hash[key] = val
        end  
      end    
    end
    return [p[0], p_hash]
  end
  
  
  @@slog = SipLogger['siplog::message'];
  def SipperUtil.find_parser_and_parse(hname, val, parse_option)
    if val.class <= SipHeaders::Header
      return val.dup
    else
      val = val.dup.to_s
    end
  #  val = val.to_s
    if hname
      klass = SipHeaders.const_get(SipperUtil.classify(hname.to_s))
    else
      str = "Not a header, cannot parse"
      @@slog.warn(str) if @@slog.warn?
      raise TypeError, str
    end
    obj = klass.new    
    obj.name = SipperUtil.headerize(hname.to_s) unless obj.name
    obj.assign(val, parse_option)
    return obj
  rescue  NameError => e
    SipperUtil.find_parser_and_parse("Header", val, parse_option)
  end
  
  
  
  # Returns the parameter value if the parameter is available. 
  def SipperUtil.get_parameter(hdr_string, param_name)
    SipperUtil.parameterize_header(hdr_string)[1][param_name.to_s]
  end
  
  # Returns true of the named parameter is present, false otherwise.
  # Can be used for valueless parameter like "lr" matching a string
  # not a header. For a Header object we can check using the hash access
  # Header.has_key?
  def SipperUtil.has_parameter_in_string?(hdr_string, param_name)
    SipperUtil.parameterize_header(hdr_string)[1].has_key?(param_name.to_s)
  end
  
  def SipperUtil.add_parameter(hdr, param, value)
    hdr << ";" << param << "=" << value
    return hdr  
  end
  
  
  def SipperUtil.cseq_number(cseq_header)
    val = cseq_header.to_s
    val = SipperUtil.header_value(cseq_header) if cseq_header =~ /:/
    m = NUMERIC_CSEQ.match(val)
    m ? m[0].strip.to_i : nil
  end
  
  
  def SipperUtil.cseq_method(cseq_header)
    val = cseq_header.to_s
    val = SipperUtil.header_value(cseq_header) if cseq_header =~ /:/
    m = val.split(/\s+/)
    if m[1] && m[1] =~ /[A-Za-z]/
      return m[1].upcase
    else
      return nil
    end
  end
  
  def SipperUtil.recordify(msg)
    unless msg.class <= Message
      msg = msg.to_s
      msg = msg.split(" ").join("_")
      msg.extend(SipperUtil::Recordable)
    end
    return msg
  end
  
  # arg can be a symbol or a boolean value true/false
  def SipperUtil.boolify(arg)
    v = nil
    if arg.is_a? Symbol
      v = SipperUtil::BOOL_MAP[arg]
    else
      v = arg
    end  
  end
  
  
  # Takes a hash and populates the 
  # instance variables of the name as keys and value as hash values
  # eg. hash =  {:b=>2, :a=>1} results in the population of the 
  # instance variables "b" and "a" to 2 and 1 respectively in the 
  # object obj.
  def SipperUtil.hash_to_iv(h, obj)
    k = nil
    v = nil
    h.each_pair {|k,v| obj.send("#{k}=", v) }
  end
  
  # take the expectaion string like "< INVITE, > 100 {2,}, > 200" and 
  # returns "< INVITE% > 100 {2,}% > 200". Such that it can be split 
  # without any ambiguity.
  def SipperUtil.make_expectation_parsable(str)
    ss = StringScanner.new(str)
    ns = ""
    while (c = ss.getch)
      if c == "{"
        in_angle = true
      elsif c == "}"
        in_angle = false
      elsif c == ","
        c = "%" unless in_angle
      end
      ns << c
    end
    return ns
  end
  
  # Takes a string or a primitive array and prints it in the standard array 
  # form and returns a string that is properly formatted ruby style array code
  # eg. ["a", "b", "c"], with elements as strings. 
  def SipperUtil.print_arr arr
    s = "["
    x = nil
    i = nil
    arr.each_with_index do |x,i|
      s +=  "'" + x.to_s + "'"
      s += "," unless i == arr.length-1
    end
    s += "]"
    return s
  end
  
  
  def SipperUtil.load_yaml(path)
    File.open(path) {|yf| YAML::load(yf)}  
  end
  
  # Formats a SipperMedia command according to the SM protocol
  def SipperUtil.formatted_media_command(str)
    sprintf("%s%s", [str.length+1].pack("N"), str)
  end
    
  def SipperUtil.print_stack_trace
    begin; raise; rescue => e; puts e.backtrace.join("\n"); end;  
  end
  
  def SipperUtil.quote_str(str)
      qs = '"' 
      qs << str << '"'
      qs
    end
    
    def SipperUtil.unquote_str(str)
      if str[0].chr == '"'
        str[1...-1]
      else
        str
      end
    end
  
  module Recordable
    def p_session_record
      'msg-info'
    end
    
    def call_id
      'precallid'
    end
  end  # module Recordable 
  
  
  
  
  # Wraps every method, except "name" because that is used to verify 
  # where the method is actually invoked.
  module WrapExtender 
  
    def WrapExtender.extended(xtendee)
      xtendee.class.instance_methods(false).each do |m|
        WrapExtender.wrap_method(xtendee.class, m) unless m.to_s == "name" 
      end
    end

    def WrapExtender.wrap_method(klass, meth)
      klass.class_eval do
        alias_method "old_#{meth}", "#{meth}"
        define_method(meth) do |*args|
          ["#{klass.name}", self.send("old_#{meth}",*args)]
        end
      end
    end
    
    def WrapExtender.last_class ret_val
      if ret_val[1].is_a? Array
        WrapExtender.last_class ret_val[1] 
      else
        ret_val[0]
      end
    end
    
  end  #WrapExtender
  
  
end
