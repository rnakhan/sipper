=begin 

RFC 2046

   boundary := 0*69<bchars> bcharsnospace

     bchars := bcharsnospace / " "

     bcharsnospace := DIGIT / ALPHA / "'" / "(" / ")" /
                      "+" / "_" / "," / "-" / "." /
                      "/" / ":" / "=" / "?"

   Overall, the body of a "multipart" entity may be specified as
   follows:

     dash-boundary := "--" boundary
                      ; boundary taken from the value of
                      ; boundary parameter of the
                      ; Content-Type field.

     multipart-body := [preamble CRLF]
                       dash-boundary transport-padding CRLF
                       body-part *encapsulation
                       close-delimiter transport-padding
                       [CRLF epilogue]

     transport-padding := *LWSP-char
                          ; Composers MUST NOT generate
                          ; non-zero length transport
                          ; padding, but receivers MUST
                          ; be able to handle padding
                          ; added by message transports.

     encapsulation := delimiter transport-padding
                      CRLF body-part

     delimiter := CRLF dash-boundary

     close-delimiter := delimiter "--"

     preamble := discard-text

     epilogue := discard-text

     discard-text := *(*text CRLF) *text
                     ; May be ignored or discarded.

     body-part := MIME-part-headers [CRLF *OCTET]
                  ; Lines in a body-part must not start
                  ; with the specified dash-boundary and
                  ; the delimiter must not appear anywhere
                  ; in the body part.  Note that the
                  ; semantics of a body-part differ from
                  ; the semantics of a message, as
                  ; described in the text.

     OCTET := <any 0-255 octet value>

  

  Example - 
     This is the preamble.  It is to be ignored, though it
     is a handy place for composition agents to include an
     explanatory note to non-MIME conformant readers.

     --simple boundary

     This is implicitly typed plain US-ASCII text.
     It does NOT end with a linebreak.
     --simple boundary
     Content-type: text/plain; charset=us-ascii

     This is explicitly typed plain US-ASCII text.
     It DOES end with a linebreak.

     --simple boundary--

     This is the epilogue.  It is also to be ignored.
  
=end
module Multipart
  
  class MimeMultipart
    
    def initialize(bodypart_arr=nil,subtype="mixed", boundary= "xxx-unique-boundary-xxx" )
      @subtype = subtype
      @boundary = boundary
      @bodypart_arr = bodypart_arr || []
    end
    
    def format_multipart
      multipart_content =""
      
      @bodypart_arr.each do |b|
      multipart_content << "\r\n--" << boundary << "\r\n"
      multipart_content << b.to_s
      end
      multipart_content << "\r\n--" << boundary << "--\r\n"
      return multipart_content
    end
    
    def to_s
      format_multipart
    end
    
    def subtype
      @subtype
    end
    
    def boundary
      @boundary
    end  
    
    def add_bodypart(part)
      @bodypart_arr << part
    end  
    
    def get_count
      return @bodypart_arr.length
    end  
    
    def get_bodypart(index)
      return @bodypart_arr[index]
    end
  end  
  
  class MimeBodypart
    
    def initialize( content, type=nil, headers=nil)
      @content = content
      @type = type.strip
      @headers = headers || []
    end  
    
    def to_s
      str =""
      str << "Content-Type: "<< @type <<"\r\n" if @type
      @headers.each do |h|
        str << h << "\r\n" if h != ""
      end  
      str << "\r\n"  
      if @content.respond_to?(:join)
         str << @content.join("\r\n")
       else
         str << @content.to_s
       end

    end
    
    def add_header_param_at(k,param)
      raise ArgumentError, "We have #{@headers.length} header lines" if @headers.length <= k
      @headers[k] << "; " + param
    end
    
    def add_header_line(line)
      @headers << line
    end  
    
    def delete_header_line_at(k)
      raise ArgumentError, "We have #{@headers.length} header lines" if @headers.length <= k
      @headers.delete_at(k)
    end   
    
    def type
      @type
    end
    
    def headers
      @headers
    end
    
    def contents
      @content
    end  
    
  end
end
