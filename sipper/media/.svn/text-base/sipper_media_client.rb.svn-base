require 'util/locator'
require 'sipper_configurator'
require 'media/sipper_media_manager'
require 'media/sipper_media_event'
require 'sip_logger'
require 'util/sipper_util'
require 'monitor'
require 'ostruct'


module Media
  class SipperDummyMediaClient 
     include SipLogger

    attr_accessor :media_id, :recv_ip, :recv_port, 
                  :send_ip, :send_port,
                  :codec, 
                  :play_spec, :record_file, 
                  :dtmf_play_spec,
                  :session
    
     def recv_ip
        return "10.10.10.10"
     end

     def recv_port
        return "6060"
     end

     def set_sdp_media(peerMedia, ourMedia)
     end

     def update_sdp_media(peerMedia, ourMedia)
     end

     def destroy_media
     end
     
     def initialize(session)
        @ilog = logger
        @ilog.debug("Dummy media client created.") if @ilog.debug?
     end

     def set_dtmf_command(cmd)
     end

     def set_media_keepalive(cmd)
     end
  end

  class SipperMediaClient
  include SipLogger
  
    attr_accessor :media_id, :recv_ip, :recv_port, 
                  :send_ip, :send_port,
                  :codec, 
                  :session

    attr_reader :play_spec, :record_file, 
                :dtmf_play_spec
    
    def play_spec=(inValue)
       return unless inValue
       @play_spec = inValue 
       @play_spec = nil if @play_spec && (@play_spec.length == 0)
    end

    def record_file=(inValue)
       return unless inValue
       @record_file = inValue 
       @record_file = nil if @record_file && (@record_file.length == 0)
    end

    def dtmf_play_spec=(inValue)
       return unless inValue
       @dtmf_play_spec = inValue 
       @dtmf_play_spec = nil if @dtmf_play_spec && (@dtmf_play_spec.length == 0)
    end

    def initialize(session)
      @session = session
      @media_manager =  Media::SipperMediaManager.instance 
      @recvpayloadnum = []
      @sendpayloadnum = []
      @codec = []
      create_media
    end
    
    def create_media(type="RTP")
      res = _send_command("COMMAND=CREATE MEDIA;MEDIATYPE=#{type}")   

      if res.result == "Success"
         @media_id = res.media_id
         @recv_ip = res.recv_ip
         @recv_port = res.recv_port
      end
    end

    def destroy_media
      res = _send_command("COMMAND=DESTROY MEDIA;MEDIAID=#{@media_id}") if @media_id

      if res.result == "Success"
         @media_id = nil
      end

    end
    
    def send_info(send_ip, send_port)
      res = _send_command("COMMAND=SEND INFO;MEDIAID=#{@media_id};SENDIP=#{send_ip};SENDPORT=#{send_port}")

      if res.result == "Success"
         @send_ip = send_ip
         @send_port = send_port
      end
    end
    
    def add_codecs(c, s, r)
      cmd = "COMMAND=ADD CODECS;MEDIAID=#{@media_id};RECVPAYLOADNUM=#{r};SENDPAYLOADNUM=#{s};CODEC=#{c}"
      cmd << ";SENDFILE=#{@play_spec}" if @play_spec && c != 'DTMF'
      cmd << ";SENDFILE=#{@dtmf_play_spec}" if @dtmf_play_spec && c == 'DTMF'
      cmd << ";RECVFILE=#{@record_file}" if @record_file && c != 'DTMF'
      res = _send_command(cmd)

      if res.result == "Success"
         @codec << r
      end
    end

    def set_dtmf_command(cmd)
      _send_command("COMMAND=SEND DTMF;MEDIAID=#{@media_id};DTMFCOMMAND=#{cmd}")
    end

    def set_media_keepalive(cmd)
      _send_command("COMMAND=MEDIA PROPERTY;MEDIAID=#{@media_id};KEEPALIVE=#{cmd}")
    end

    def set_status(status)
      _send_command("COMMAND=SET STATUS;MEDIAID=#{@media_id};MEDIASTATUS=#{status.upcase}")  
    end

    def clear_codecs()
      _send_command("COMMAND=CLEAR CODECS;MEDIAID=#{@media_id}")  
      @codec.clear
    end
    
    def _send_command(cmd)
       result = @media_manager.send_command(self, cmd)
       return result
    end

    def SipperMediaClient.get_supported_codecs
       return ["G711U", "G711A", "DTMF"]
    end

    def SipperMediaClient.get_dtmf_codec(medialine)
      medialine[:a].split("||").each do |val|
         return val.split(" ")[0].split(":")[1].to_i if val.include?("telephone-event")
      end

      return nil
    end

    def set_sdp_media(ourMedia, peerMedia)
      clear_codecs 
      peerCLine = peerMedia[:c] 
      peerMLine = peerMedia[:m]

      peerMLineVars = peerMLine.split(" ")
      peerCLineVars = peerCLine.split(" ")
      send_info(peerCLineVars[2], peerMLineVars[1])

      peerCodecs = peerMLineVars[3..-1]
      ourCodecs = ourMedia[:m].split(" ")[3..-1]

      if peerCodecs.include?("0") && ourCodecs.include?("0")
         add_codecs("G711U", 0, 0)
      else
         if peerCodecs.include?("8") && ourCodecs.include?("8")
            add_codecs("G711A", 8, 8)
         end
      end

      peerdtmf = SipperMediaClient::get_dtmf_codec(peerMedia)
      ourdtmf = SipperMediaClient::get_dtmf_codec(ourMedia)

      if peerdtmf && ourdtmf
         add_codecs("DTMF", peerdtmf, ourdtmf)
      end

      ourstatus = "SENDRECV"
      ourMedia[:a].split("||").each do |val|
         ourstatus = "INACTIVE" if val == "inactive"
         ourstatus = "SENDONLY" if val == "recvonly"
         ourstatus = "RECVONLY" if val == "sendonly"
      end

      set_status(ourstatus)
    end

    def update_sdp_media(peerMedia, ourMedia)
      peerCLine = peerMedia[:c] 
      peerMLine = peerMedia[:m]

      peerMLineVars = peerMLine.split(" ")
      peerCLineVars = peerCLine.split(" ")

      if (peerMedia[:m].split(" ")[1].to_i == 0 ||
         ourMedia[:m].split(" ")[1].to_i == 0)
         clear_codecs 
         return
      end

      send_info(peerCLineVars[2], peerMLineVars[1])

      peerCodecs = peerMLineVars[3..-1]
      ourCodecs = ourMedia[:m].split(" ")[3..-1]

      if peerCodecs.include?("0") && ourCodecs.include?("0") 
         if @codec.include?(8)
            set_sdp_media(ourMedia, peerMedia)
            return
         end
         add_codecs("G711U", 0, 0) unless @codec.include?(0)
      else
         if @codec.include?(0)
            set_sdp_media(ourMedia, peerMedia)
            return
         end
         if peerCodecs.include?("8") && ourCodecs.include?("8")
            add_codecs("G711A", 8, 8) unless @codec.include?(8)
         else
            if @codec.include?(8)
               set_sdp_media(ourMedia, peerMedia)
               return
            end
         end
      end

      peerdtmf = nil
      peerMedia[:a].split("||").each do |val|
         peerdtmf = val.split(" ")[0].split(":")[1] if val.include?("telephone-event")
      end
      ourdtmf = nil
      ourMedia[:a].split("||").each do |val|
         ourdtmf = val.split(" ")[0].split(":")[1] if val.include?("telephone-event")
      end

      if peerdtmf && ourdtmf
         add_codecs("DTMF", peerdtmf, ourdtmf) unless @codec.include?(peerdtmf)
         diffcodec = @codec - [0, 8, peerdtmf]
         if diffcodec.length > 0
            set_sdp_media(ourMedia, peerMedia)
            return
         end
      else
         diffcodec = @codec - [0, 8]
         if diffcodec.length > 0
            set_sdp_media(ourMedia, peerMedia)
            return
         end
      end

      ourstatus = "SENDRECV"
      ourMedia[:a].split("||").each do |val|
         ourstatus = "INACTIVE" if val == "inactive"
         ourstatus = "SENDONLY" if val == "sendonly"
         ourstatus = "RECVONLY" if val == "recvonly"
      end

      set_status(ourstatus)
    end
    
    private :_send_command
    
  end 
end
