require 'sdp/sdp'
require 'sipper_configurator'


module SDP
  class SdpGenerator
    
    #    v=0    
    #    o=<username> <sess-id> <sess-version> <nettype> <addrtype>
    #        <unicast-address>
    #    e.g. o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
    #  
    #    s=<session name>
    #    s=SDP Seminar
    #   
    #    c=<nettype> <addrtype> <connection-address>
    #    c=IN IP4 192.168.1.2
    # 
    #    t=<start-time> <stop-time>
    #    To convert these values to UNIX time, subtract
    #    decimal 2208988800.
    
    
    
    
    def self.make_no_media_sdp(session_hash=nil, ip = nil)
      sdp = SDP::Sdp.new
      sdp.session_lines = session_hash || {}
      
      if sdp.session_lines[:v].nil?
        sdp.session_lines[:v] = "0"
      end

      ip = SipperConfigurator[:SdpIP] unless ip
      ip = SipperConfigurator[:LocalSipperIP] unless ip

      if sdp.session_lines[:o].nil?
        tm = Time.new.tv_sec
        sdp.session_lines[:o] = 
        sprintf("nkhan %s %s IN IP4 %s", tm, tm, ip)
      end
      if sdp.session_lines[:s].nil?
        sdp.session_lines[:s] = "Sipper Session"
      end
      if sdp.session_lines[:c].nil?
        sdp.session_lines[:c] = 
        sprintf("IN IP4 %s", ip)
      end
      if sdp.session_lines[:t].nil?
        sdp.session_lines[:t] = (Time.new.tv_sec + 2208988800).to_s + " 0"
      end
      sdp
    end
    
    def self.make_sdp_media(ip, port, codecs, status)
       h = {}
       ma = []

       h[:c] = sprintf("IN IP4 %s", ip.to_s.chomp) if ip
       if codecs.include?('G711U')
         h[:m] =   sprintf("audio %s RTP/AVP 0", port.to_s.chomp)
         ma << 'rtpmap:0 PCMU/8000'        
       end
       if codecs.include?('G711A')
         if h[:m]
           h[:m] << " 8"
         else  
           h[:m] =   sprintf("audio %s RTP/AVP 8", port.to_s.chomp)
         end
         ma << 'rtpmap:8 PCMA/8000'
       end
       if codecs.include?('DTMF')
         if h[:m]
           h[:m] << " 101"
         else  
           h[:m] = sprintf("audio %s RTP/AVP 101", port.to_s.chomp)
         end
         ma << 'rtpmap:101 telephone-event/8000'
       end

       unless h[:m]
         h[:m] =   sprintf("audio 0 RTP/AVP 0", port.to_s.chomp)
         ma << 'rtpmap:0 PCMU/8000'        
       end

       ma << status

       ma.each do |a|
         unless h[:a]
           h[:a] = a 
         else
           h[:a] << "||" << a
         end
       end

       return h
    end

    def self.make_sdp(session_hash, ip, port, codecs, type)
      sdp = make_no_media_sdp(session_hash, ip)
      h = {}
      ma = []
      if codecs.include?('G711U')
        h[:m] =   sprintf("audio %s RTP/AVP 0", port.to_s.chomp)
        ma << 'rtpmap:0 PCMU/8000'        
      end
      if codecs.include?('G711A')
        if h[:m]
          h[:m] << " 8"
        else  
          h[:m] =   sprintf("audio %s RTP/AVP 8", port.to_s.chomp)
        end
        ma << 'rtpmap:8 PCMA/8000'
      end
      if codecs.include?('DTMF')
        if h[:m]
          h[:m] << " 101"
        else  
          h[:m] = sprintf("audio %s RTP/AVP 101", port.to_s.chomp)
        end
        ma << 'rtpmap:101 telephone-event/8000'
      end
      sdp.add_media_lines(h)
      sdp.add_media_attribute_at(0, type.downcase) if type
      ma.each do |a|
        sdp.add_media_attribute_at(0, a)    
      end
      sdp
    end
    
  end # class
end
