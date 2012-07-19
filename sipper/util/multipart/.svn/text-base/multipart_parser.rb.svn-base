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

require 'util/multipart/mime_multipart'

module Multipart
 
  class MultipartParser
    
    def self.parse(arr, type)
      type_val =type.header_value
      multipart_content = Multipart::MimeMultipart.new(nil, type_val.slice(type_val.index("/")+1 .. -1), type.boundary)
      while arr[0] != "--"+type.boundary+"--" and arr.index("--"+type.boundary)!= nil
        arr.slice!(0 .. arr.index("--"+type.boundary))
        if arr.index("--"+type.boundary)
          b1 = arr.slice!(0 .. arr.index("--"+type.boundary)-1) 
        else
          b1 = arr.slice!(0 .. arr.length() -2 )   
        end 
        
        blank_line = false
        header = []
        content = []
        bodytype =""
        b1.each do |line|
          if line =~ /^Content-Type/
            bodytype= line.slice(line.index(":")+1 .. -1)
            next
          end  
          blank_line ? content << line : header << line
          blank_line = true if line.empty?
        end
        part  = Multipart::MimeBodypart.new(content, bodytype,header)
        multipart_content.add_bodypart(part)
      end  
      return multipart_content
    end  
  end # class
  
end
