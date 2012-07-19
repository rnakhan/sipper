
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

require 'sdp/sdp'

module SDP
 
  class SdpParser
    

    def self._copy_default_from_session(session, h)
       if session[:c] 
          h[:c] = session[:c] unless h[:c]
       end

       sessionStatus = nil

       if session[:a]
          session[:a].split("||").each do |val|
             sessionStatus = "inactive" if val == "inactive"
             sessionStatus = "sendrecv" if val == "sendrecv"
             sessionStatus = "recvonly" if val == "recvonly"
             sessionStatus = "sendonly" if val == "sendonly"
          end
       end

       mediaStatus = nil

       if h[:a]
          h[:a].split("||").each do |val|
             mediaStatus = "inactive" if val == "inactive"
             mediaStatus = "sendrecv" if val == "sendrecv"
             mediaStatus = "recvonly" if val == "recvonly"
             mediaStatus = "sendonly" if val == "sendonly"
          end
       end

       if (sessionStatus != nil) && (mediaStatus == nil)
         unless h[:a] 
            h[:a] = sessionStatus
         else
            h[:a] << "||" << sessionStatus
         end
       end
    end

    def self.parse(arr, addDefault = false)
      parsing_session = true
      h = {}
      sdp = SDP::Sdp.new
      arr.each do |line|
        line.strip!
        next unless line =~ /=/
        n, v = line.split("=", 2)
        if n == "m" 
          if parsing_session
            sdp.session_lines = h
            h = {}
            parsing_session = false
          else
            if addDefault
               _copy_default_from_session(sdp.session_lines, h)
            end
            sdp.add_media_lines(h)
            h = {}
          end
        end
        if h[n.to_sym].nil?
          h[n.to_sym] = v
        else
          h[n.to_sym] << "||" << v
        end
      end # each
      if parsing_session
        sdp.session_lines = h
      else
        if addDefault
           _copy_default_from_session(sdp.session_lines, h)
        end
        sdp.add_media_lines(h)
      end
      return sdp
    end  
  end # class
  
end
