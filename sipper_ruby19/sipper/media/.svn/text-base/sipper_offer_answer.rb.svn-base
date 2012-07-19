require 'media/sipper_media_client'

module Media
class SipperOfferAnswer
   include SipLogger
   attr_accessor :peerSdp, :ourSdp,
                 :playspec, :recspec, :dtmfspec

=begin
  state values
     0 = None
     1 = Stable (After Offer and Answer.)
     2 = PeerOffered
     3 = OurOffered
     4 = OfferGenerated
=end

   def initialize(session)
      @ilog = logger
      @session = session
      @state = 0
      @client = []
   end

   def close()
      @ilog.debug("Media close called.") if @ilog.debug?
      @client.each do |curr|
         @ilog.debug("Calling close on #{curr}") if @ilog.debug?
         curr.destroy_media if curr
      end
   end

   def setup_media_spec(playspec, recspec, dtmfspec)
      @playspec = playspec
      @recspec = recspec
      @dtmfspec = dtmfspec

      @client.each do |currclient|
         if currclient
            currclient.set_dtmf_command(dtmfspec) if dtmfspec
         end
      end
   end

   def set_media_keepalive(keepalive = 30)
      @client.each do |currclient|
         if currclient
            currclient.set_media_keepalive(keepalive) 
         end
      end
   end

   def make_new_offer(codecs = nil, status = "sendrecv")
      return if @state == 2 || @state == 3
      codecs = SipperMediaClient::get_supported_codecs unless codecs

      unless @client[0]
         @client[0] = SipperMediaClient.new(@session) if SipperConfigurator[:SipperMedia]
         @client[0] = SipperDummyMediaClient.new(@session) unless @client[0]
      end

      if @state == 0
         @ourSdp = SDP::SdpGenerator.make_sdp(nil, @client[0].recv_ip, @client[0].recv_port, codecs, status)
      else
         currversion = @ourSdp.get_owner_version
         @ourSdp = SDP::SdpGenerator.make_sdp(@ourSdp.session_lines, @client[0].recv_ip, @client[0].recv_port, codecs, status)
         @ourSdp.set_owner_version(currversion + 1)
      end

      @state = 4
   end

   def get_sdp()
      return @ourSdp if (@state==4 || @state==2)
   end     
    

   def _make_our_answer()
      @ilog.debug("Client making new answer") if @ilog.debug?
      peerMediaLines = @peerSdp.media_lines
      unless @client[0]
         @client[0] = SipperMediaClient.new(@session) if SipperConfigurator[:SipperMedia]
         @client[0] = SipperDummyMediaClient.new(@session) unless @client[0]
      end

      @ourSdp = SDP::SdpGenerator.make_no_media_sdp(nil, @client[0].recv_ip) unless @ourSdp 
      @ourSdp.media_lines = [] unless @ourSdp.media_lines

      versionchange = false

      length = 0
      length = peerMediaLines.length if peerMediaLines

      (0..length - 1).each do |idx|
         unless @client[idx]
            @client[idx] = SipperMediaClient.new(@session) if SipperConfigurator[:SipperMedia]
            @client[idx] = SipperDummyMediaClient.new(@session) unless @client[idx]
         end

         @client[idx].play_spec = @playspec
         @client[idx].record_file = @recspec
         @client[idx].dtmf_play_spec = @dtmfspec

         currPeerM = peerMediaLines[idx]
         peerCodecs = SDP::get_codecs_in_media(currPeerM)
         ourCodecs = peerCodecs

         ourCodecs.delete("G711A") if ourCodecs.include?("G711U")
         ourMediaStatus = SDP::get_answer_status(SDP::get_media_status(currPeerM))

         ourMedia = SDP::SdpGenerator.make_sdp_media(nil, @client[idx].recv_port, ourCodecs, ourMediaStatus)
         SDP.copy_media_type_transport(currPeerM, ourMedia)

         if @ourSdp.media_lines[idx]
            unless SDP::is_media_equal(ourMedia, @ourSdp.media_lines[idx])
               @ourSdp.media_lines[idx] = ourMedia
               versionchange = true
            end
         else
            @ourSdp.media_lines[idx] = ourMedia
            versionchange = true
         end
      end

      if(versionchange)
         @ourSdp.increment_owner_version
      end
   end

   def refresh_sipper_media()
      return unless SipperConfigurator[:SipperMedia]
      return unless (@peerSdp && @ourSdp)
      
      peerMediaLines = @peerSdp.media_lines
      ourMediaLines = @ourSdp.media_lines

      length = peerMediaLines.length
      (0..length - 1).each do |idx|
         @client[idx].play_spec = @playspec
         @client[idx].record_file = @recspec
         @client[idx].dtmf_play_spec = @dtmfspec
         @client[idx].set_sdp_media(ourMediaLines[idx], peerMediaLines[idx]) if @client[idx]
      end
      length = 1 if length == 0
      (length..@client.length - 1).each do |idx|
         @client[idx].destroy_media if @client[idx]
         @client[idx] = nil
      end
   end

   def update_sipper_media()
      return unless SipperConfigurator[:SipperMedia]

      @ilog.debug("update_sipper_media PeerSDP:\n#{@peerSdp}\nOurSDP:\n#{ourSdp}\n") if @ilog.debug?
      peerMediaLines = @peerSdp.media_lines
      ourMediaLines = @ourSdp.media_lines

      length = peerMediaLines.length
      (0..length - 1).each do |idx|
         @client[idx].update_sdp_media(peerMediaLines[idx], ourMediaLines[idx]) if @client[idx]
      end
      length = 1 if length == 0
      (length..@client.length - 1).each do |idx|
         @client[idx].destroy_media if @client[idx]
         @client[idx] = nil
      end
   end

   def _check_peer_offer(inPeerSdp)
      @state = 2
      if @peerSdp == nil
         @peerSdp = inPeerSdp.clone()
         _make_our_answer() 
      elsif (inPeerSdp.get_owner_version() == @peerSdp.get_owner_version())
         return
      else
         @peerSdp = inPeerSdp.clone()
         _make_our_answer()
      end

      update_sipper_media()
   end

   def _check_peer_answer(peerSdp)
      currVersion = @ourSdp.get_owner_version
      _check_peer_offer(peerSdp)
      @ourSdp.set_owner_version(currVersion)
      @state = 1
   end

   def handle_incoming_request(request)
      if request.method == "INVITE"
         @last_recv_invite = request
      end

      return unless request.sdp
      return unless (request.method == "INVITE" || request.method == "ACK" || request.method == "UPDATE" || request.method == "PRACK")
      return unless (@state != 2)

      case @state
      when 0
         return if request.method != "INVITE"
         _check_peer_offer(request.sdp)
      when 1
         return if request.method == "ACK"
         _check_peer_offer(request.sdp)
      when 3
         return if request.method == "UPDATE" || request.method == "INVITE"
         _check_peer_answer(request.sdp)
      when 4
         return if request.method == "ACK" && @peerSdp
         return if request.method != "INVITE" && (@peerSdp == nil)
         _check_peer_offer(request.sdp)
      end
   end

   def handle_incoming_response(response)
      return unless response.sdp 
      return unless (response.get_request_method == "INVITE" || response.get_request_method == "PRACK" || response.get_request_method == "UPDATE")
      return unless (@state != 2)

      return if response.code <= 100
      return if response.code > 300
      if response.code < 200
         if SipperConfigurator[:ProtocolCompliance] == 'strict'
           return unless response["require".to_sym]
           return unless response.require.to_s.include?("100rel")
         end  
      end

      case @state
      when 0
         return if response.get_request_method != "INVITE"
         _check_peer_offer(response.sdp)
      when 1
         return if response.get_request_method != "INVITE"
         _check_peer_offer(response.sdp)
      when 3
         _check_peer_answer(response.sdp)
      when 4
         return if response.get_request_method != "INVITE"
         _check_peer_offer(response.sdp)
      end
   end

   def handle_outgoing_request(request)
      return unless (request.method == "INVITE" || request.method == "PRACK" || request.method == "UPDATE" || request.method == "ACK")

      case @state
      when 0
         return
      when 1
         return
      when 2
         return if request.method == "INVITE" || request.method == "UPDATE"
         request.sdp = @ourSdp.clone()
         @state = 1
      when 3
         return
      when 4
         return if request.method == "ACK"
         request.sdp = @ourSdp.clone()
         @state = 3
      end
   end

   def handle_outgoing_response(response)
      
      return unless (response.get_request_method == "INVITE" || response.get_request_method == "PRACK" || response.get_request_method == "UPDATE")

      return if response.code <= 100
      return if response.code > 300
      if response.code < 200
         if SipperConfigurator[:ProtocolCompliance] == 'strict'
           return unless response["require".to_sym]
           return unless response.require.to_s.include?("100rel")
         end
      end

      @ilog.debug("Outgoing response checking state #{@state}") if @ilog.debug?
      case @state
      when 0
         return
      when 1
         return if response.get_request_method != "INVITE"
         return if @last_recv_invite.sdp 
         response.sdp = @ourSdp.clone()
         @state = 3
         return
      when 2
         response.sdp = @ourSdp.clone()
         @state = 1
      when 3
         return
      when 4
         return if response.get_request_method != "INVITE"
         response.sdp = @ourSdp.clone()
         @state = 3
      end
   end
end
end
