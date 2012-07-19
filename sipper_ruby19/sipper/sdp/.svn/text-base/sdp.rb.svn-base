=begin 

RFC 4566

  Session description
         v=  (protocol version)
         o=  (originator and session identifier)
         s=  (session name)
         i=* (session information)
         u=* (URI of description)
         e=* (email address)
         p=* (phone number)
         c=* (connection information -- not required if included in
              all media)
         b=* (zero or more bandwidth information lines)
         One or more time descriptions ("t=" and "r=" lines; see below)
         z=* (time zone adjustments)
         k=* (encryption key)
         a=* (zero or more session attribute lines)
         Zero or more media descriptions

      Time description
         t=  (time the session is active)
         r=* (zero or more repeat times)

      Media description, if present
         m=  (media name and transport address)
         i=* (media title)
         c=* (connection information -- optional if included at
              session level)
         b=* (zero or more bandwidth information lines)
         k=* (encryption key)
         a=* (zero or more media attribute lines)

  

  Example - 
  v=0
  o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
  s=SDP Seminar
  i=A Seminar on the session description protocol
  u=http://www.example.com/seminars/sdp.pdf
  e=j.doe@example.com (Jane Doe)
  c=IN IP4 224.2.17.12/127
  t=2873397496 2873404696
  a=recvonly
  m=audio 49170 RTP/AVP 0
  m=video 51372 RTP/AVP 99
  a=rtpmap:99 h263-1998/90000
  
=end
module SDP
  
  class Sdp
    
    def session_lines=(h)
      if @sa 
        @sa[:v] = h[:v] if h[:v]
        @sa[:o] = h[:o] if h[:o]
        @sa[:s] = h[:s] if h[:s]
        @sa[:c] = h[:c] if h[:c]
        @sa[:t] = h[:t] if h[:t]
      else
        @sa=h        
      end
    end
    
    # media lines are an ordered array 
    # where each media line is an array member
    # modeled as a hash
    def add_media_lines(h)
      @ma ||= []
      @ma << h
    end

    def remove_media_line_at(k)
      @ma.delete_at(k)  
    end
    
    # a=xxx
    def add_media_attribute_at(k, attr, type=:a)
      raise ArgumentError, "We have #{@ma.length} media lines" if @ma.length <= k 
      if @ma[k][type].nil? || @ma[k][type].length == 0 
        @ma[k][type] = attr
      else
        @ma[k][type] << "||" << attr
      end
    end
    
    def remove_media_attribute_at(k, attr, type=:a)
      raise ArgumentError, "We have #{@ma.length} media lines" if @ma.length <= k 
      unless @ma[k][type].nil?
        @ma[k][type] = (@ma[k][type].split("||").reject {|v| v == attr }).join("||")  
      end
    end
    
    def get_media_attributes_at(k, type=:a)
      raise ArgumentError, "We have #{@ma.length} media lines" if @ma.length <= k
      @ma[k][type].split("||")
    end
    
    def session_lines
      @sa  
    end
    
    def media_lines
      @ma  
    end

    def media_lines=(val)
      @ma = val
    end
    
    def format_sdp(separator="\r\n")
      sdp = ""
      
      # session lines
      [ :v, :o, :s, :i, :u, :e, :p, :c, :b, :z, :k, :t, :r, :a].each do |attr|
        unless self.session_lines[attr].nil?
          self.session_lines[attr].split("||").each do |v|
            sdp << sprintf("%s=%s%s", attr.to_s, v, separator)
          end
        end
      end
      
      # media lines
      if media_lines
        media_lines.each do |ma|
          [ :m, :i, :c, :b, :k, :a ].each do |attr|
            unless ma[attr].nil?
              ma[attr].split("||").each do |v|
                sdp << sprintf("%s=%s%s", attr.to_s, v, separator)
              end
            end
          end
        end
      end
      return sdp
    end
    
    def to_s
      format_sdp
    end

    def get_owner_version
       return @sa[:o].split(" ")[2].to_i
    end

    def set_owner_version(inVersion)
       vals = @sa[:o].split(" ")
       vals[2] = inVersion.to_s
       @sa[:o] = vals.join(" ")
    end
    def increment_owner_version
       vals = @sa[:o].split(" ")
       vals[2] = (vals[2].to_i + 1).to_s
       @sa[:o] = vals.join(" ")
    end

    def clone
      ret = Sdp.new

      [ :v, :o, :s, :i, :u, :e, :p, :c, :b, :z, :k, :t, :r, :a].each do |attr|
        unless @sa[attr].nil?
          ret.session_lines = {} unless ret.session_lines
          ret.session_lines[attr] = @sa[attr]
        end
      end
      
      # media lines
      if @ma
        ret.media_lines = []
        @ma.each do |ma|
          currattr = {}
          [ :m, :i, :c, :b, :k, :a ].each do |attr|
            unless ma[attr].nil?
              currattr[attr] = ma[attr]
            end
          end
          ret.media_lines << currattr
        end
      end

      return ret
    end
  end

  def SDP.check_codec_in_media(media, codec)
     return media[:m].split(" ")[3..-1].include?("0") if codec == "G711U"
     return media[:m].split(" ")[3..-1].include?("8") if codec == "G711A"
     if codec == "DTMF"
        media[:a].split("||").each do |val|
           return true if val.include?("telephone-event")
        end
     end

     return nil
  end

  def SDP.get_codecs_in_media(media)
     codec = []

     codecnums = media[:m].split(" ")[3..-1]

     codec << "G711U" if codecnums.include?("0")
     codec << "G711A" if codecnums.include?("8")

     if media[:a]
        media[:a].split("||").each do |val|
              codec << "DTMF" if val.include?("telephone-event")
        end
     end

     return codec
  end

  def SDP.get_media_status(media)
     retStatus = "sendrecv"

     if media[:a]
        media[:a].split("||").each do |val|
           retStatus = "inactive" if val == "inactive"
           retStatus = "sendrecv" if val == "sendrecv"
           retStatus = "recvonly" if val == "recvonly"
           retStatus = "sendonly" if val == "sendonly"
        end
     end

     return retStatus
  end

  def SDP.get_answer_status(status)
     return "inactive" if status == "inactive"
     return "recvonly" if status == "sendonly"
     return "sendrecv" if status == "sendrecv"
     return "sendonly" if status == "recvonly"
     return "sendrecv"
  end

  def SDP.is_media_equal(media1, media2)
     return false if media1[:m] != media2[:m]
     return false if SDP.get_media_status(media1) != SDP.get_media_status(media2)
     return true
  end

  def SDP.set_media_type(media, intype)
     vals = media[:m].split(" ")
     vals[0] = intype
     media[:m] = vals.join(" ")
  end

  def SDP.get_media_type(media)
     return media[:m].split(" ")[0]
  end

  def SDP.set_media_transport(media, transport)
     vals = media[:m].split(" ")
     vals[2] = transport
     media[:m] = vals.join(" ")
  end

  def SDP.get_media_transport(media)
     return media[:m].split(" ")[2]
  end

  def SDP.copy_media_type_transport(media1, media2)
     SDP.set_media_type(media2, SDP.get_media_type(media1))
     SDP.set_media_transport(media2, SDP.get_media_transport(media1))
  end
end
