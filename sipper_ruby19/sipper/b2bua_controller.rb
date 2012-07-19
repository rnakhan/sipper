require 'base_controller'

module SIP

  class B2buaController < SIP::BaseController
    
    def initialize
       @ilog = SipLogger['siplog::sip_basecontroller']
    end

    # Gets or creates a peer b2bua leg (session). The session passed in as the 
    # argument becomes the anchor leg which is the main leg. 
    def get_or_create_peer_session(session, rip=SipperConfigurator[:DefaultRIP], 
          rp=SipperConfigurator[:DefaultRP] )
      peer = get_peer_session(session)
      peer = create_peer_session(session, rip, rp) unless peer
      session.offer_answer = nil
      peer.offer_answer = nil
      peer
    end
    
    def create_peer_session(session, rip=SipperConfigurator[:DefaultRIP], 
          rp=SipperConfigurator[:DefaultRP] )
      # todo take care of TCP
      peer = create_udp_session(rip, rp)
      session[:_sipper_b2b_peer] = peer
      peer[:_sipper_b2b_peer] = session
      peer.use_b2b_session_lock_from(session)
      peer
    end
    
    def get_peer_session(session)
      session[:_sipper_b2b_peer]
    end
    
    
    # While linking the two sessions to create a b2bua the first 
    # argument is treated as the main or anchor leg. 
    def link_sessions(session1, session2)
      unlink_session(session1, session1[:_sipper_b2b_peer]) if session1[:_sipper_b2b_peer]
      session1[:_sipper_b2b_peer] = session2
      session2[:_sipper_b2b_peer] = session1
      session2.use_b2b_session_lock_from(session1)
    end
    
    # Unlinking removes the b2bua association. 
    def unlink_sessions(session1, session2)
      if session1.b2b_anchor_leg?
        anchor_leg = session1
        peer_leg = session2
      else
        anchor_leg = session2
        peer_leg = session1
      end
      anchor_leg[:_sipper_b2b_peer] = nil
      peer_leg[:_sipper_b2b_peer] = nil
      peer_leg.revert_to_local_session_lock
    end
    
    
    # Creates the b2bua request based on the original request. Also creates the 
    # peer session if it does not already exist. 
    def create_b2bua_request(session, orig_request=session.irequest, rip=SipperConfigurator[:DefaultRIP], 
          rp=SipperConfigurator[:DefaultRP])
      peer_session = get_or_create_peer_session(session, rip, rp)
      if peer_session.initial_state?
        r = peer_session.create_initial_request(orig_request.method, orig_request.uri)
        r.copy_from(orig_request, :from, :to, :route, :content, :content_type, :path, :service_route, :privacy, :referred_by, :p_asserted_identity)
        r.from.tag = "3"
      else
        if(orig_request.method == "CANCEL")
          r = peer_session.create_cancel
        elsif(orig_request.method == "ACK")
          r = peer_session.create_ack
        else
          r = peer_session.create_subsequent_request(orig_request.method)
        end  
        r.copy_from(orig_request, :content, :content_type)
      end  
      return r
    end
    
    
    # Creates a b2bua response based on an original response. 
    # If there is no peer session then this fails. 
    def create_b2bua_response(session, orig_response=session.iresponse)
      peer_session = get_peer_session(session)
      if peer_session
        r = peer_session.create_response(orig_response.code)
        r.copy_from(orig_response,  :content, :content_type, :path, :service_route, :privacy, :warning)
        return r
      else
        @ilog.warn("No peer session found, cannot create the response") if @ilog.warn?
        raise "Unable to create response"
      end 
    end
    
    # Invalidates this b2bua sessions. 
    def invalidate_sessions(session, flag=true)
      peer_session = get_peer_session(session)
      peer_session.invalidate(flag) if peer_session
      session.invalidate(flag)
    end
    
    
    # Transparently passes / relays the request given a peer session 
    # exists. 
    def relay_request(session)
      peer_session = get_peer_session(session)
      if peer_session
        r = create_b2bua_request(session)
        peer_session.send(r)
      else
        @ilog.warn("No peer session found, cannot relay the request") if @ilog.warn?
        raise "Unable to relay the request" 
      end
    end
    
    # Transparently passes / relays the response given a peer session 
    # exists. 
    def relay_response(session)
      peer_session = get_peer_session(session)
      if peer_session
        r = create_b2bua_response(session)
        peer_session.send(r)
      else
        @ilog.warn("No peer session found, cannot relay the response") if @ilog.warn?
        raise "Unable to relay the response" 
      end
    end
    
    
    # Marks this b2bua as transparent which allows the relaying of requests and 
    # responses between legs without any controller involvement. 
    def go_transparent(session, state=true)
      session[:_sipper_b2b_transparent] = state
      peer_session = get_peer_session(session)
      peer_session[:_sipper_b2b_transparent] = state if peer_session
    end
    
    
    # if there exists a peer session then we transparently send the request as a b2bua
    # if transparent flag is on. 
    def on_request(session)
      peer_session = get_peer_session(session)
      if peer_session && session[:_sipper_b2b_transparent]
        peer_session.request_with(session.irequest.method)
      else
        super
      end
    end
    
    
    # if there exists a peer session then we transparently pass the response as a b2bua
    # if transparent flag is true 
    def on_response(session)
      peer_session = get_peer_session(session)
      if peer_session && session[:_sipper_b2b_transparent]
        peer_session.respond_with(session.iresponse.code)
      else
        super
      end
    end
    
    
    # Provides Privacy service to users, user can call this API after creating 
    # the request or response to apply the privacy. 
    def apply_privacy(msg)
      if !msg[:privacy] || msg[:privacy].to_s == "none"
        return msg
      else
        if msg.privacys.include?("user")
          if msg.class == Request  
            if msg.method == "REFER"
              msg.referred_by ='sip:anonymous@anonymous.invalid'
            end
            msg.from.uri = "sip:anonymous@anonymous.invalid"
            msg.from.display_name ='"Anonymous"' 
          elsif msg[:warning]
            warn_code,warn_agent,warn_text  = msg.warning.to_s.split(' ',3)
            msg.warning = warn_code + " " + warn_text
          end  
        end    
        msg.privacy = nil
        return msg
      end    
    end  
    
  end
end
