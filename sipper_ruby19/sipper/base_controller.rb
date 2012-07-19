# Here is where a lot of magic will happen, this will enable a lot of 
# controller functionality

require 'sip_logger'
require 'util/sipper_util'
require 'response'
require 'request'
require 'session'
require 'detached_session'
require 'util/locator'

module SIP
  class BaseController
    include SipLogger
    
    # civ set for each individual controllers
    @sol = false
    @tr_usage = nil
    @tr_timers = nil
    @sess_timer = nil
    @tr_handlers = nil
    @sess_timer = nil
    @sess_limit = nil
    @t2xx_usage = nil
    @t1xx_retran_usage = nil
    @t2xx_timers = nil
    @t1xx_timers = nil
    @header_order = nil
    @pre_existing_rs = nil
    @compact_headers = nil
    @session_record = nil
    @behind_nat = false
    @emit_console
     
    def self.start_on_load(val)
      @sol = SipperUtil.boolify(val)  
    end
    
    def self.start_on_load?
      @sol
    end

    def self.behind_nat(val)
      @behind_nat = val
    end
    
    def self.get_behind_nat
      @behind_nat
    end
    
    
    def self.realm(val)
      @realm = val  
    end
    
    def self.get_realm
      @realm
    end
    
    def self.emit_console(val)
      @emit_console = val
    end
    
    def self.get_emit_console
      @emit_console
    end
    
    # The transaction usage hash setting is like a modifier in the 
    # controller. The setting is exactly same as the configuration setting
    # eg transaction_usage :use_transactions=>true, :use_ict=>false, :use_nict=>true
    # 
    def self.transaction_usage(hash)
      @tr_usage = hash
    end
   
    def self.get_transaction_usage
      @tr_usage
    end
    
    # The transaction timers can be set at the controller level which override the 
    # default timer configuration. Eg. usage
    #   transaction_timers :t1=>100, :ta=200
    # Here the modifier is setting the T1 timer value to 100 msec and TimerA to 200 msec. 
    def self.transaction_timers(hash)
      @tr_timers = hash
    end
    
    def self.get_transaction_timers
      @tr_timers
    end
    
    # value can be msg-info or msg-debug
    def self.session_record(val)
      @session_record = val.to_s  
    end
    
    def self.get_session_record
      @session_record
    end
    
    # transaction_handlers :Ict=>MyIctHandler, :Nict=>MyNictHandler, :Base=>CatchAllHandler
    def self.transaction_handlers(hash)
      @tr_handlers = hash
    end
    
    def self.get_transaction_handlers
      @tr_handlers
    end
    
    
    # The session timer for session invalidation, the default is taken from the configuration
    # :SessionTimer
    def self.session_timer(val)
      @sess_timer = val
    end
    
    def self.get_session_timer
      @sess_timer
    end
    
    # the upper limit of session lifetime, defaults to :SessionLimit from configuration. 
    def self.session_limit(val)
      @sess_limit = val
    end
    
    def self.get_session_limit
      @sess_limit
    end
    
    def self.t2xx_usage(val)
      @t2xx_usage = val  
    end
    
    def self.get_t2xx_usage
      @t2xx_usage
    end
    
    def self.t1xx_retran_usage(val)
      @t1xx_retran_usage = val  
    end
    
    def self.get_t1xx_retran_usage
      @t1xx_retran_usage
    end
    
    # the hash of 3 timer values that affect 2xx retransmissions for UAS 
    # i.e {:Start=>100, :Cap=>400, :Limit=>1600} that roughly 
    # correspond with T1, T2 and 64*T1 respectively, which are also the
    # defaults. The argument hash doesnt have to be all the three values 
    # but any that are required to be overridden.
    def self.t2xx_timers(hash)
      @t2xx_timers = hash
    end
    
    def self.get_t2xx_timers
      @t2xx_timers
    end
    
    def self.t1xx_timers(hash)
      @t1xx_timers = hash
    end
    
    def self.get_t1xx_timers
      @t1xx_timers
    end
    
    
    def self.header_order(*arr)
      if arr[0].is_a?(Array)
        @header_order = arr[0] 
      else
        @header_order = arr
      end
    end
    
    def self.get_header_order
      @header_order
    end
    
    # Directive for setting compact headers for outgoing requests for 
    # this controller. The headers can be defined by their sipper symbols
    # like :call_id and :via or you can chose to have :all_possible in which 
    # Sipper use compact form for all headers that have a compact form. 
    def self.use_compact_headers(*arr)
      if arr[0].is_a?(Array)
        @compact_headers = arr[0] 
      else
        @compact_headers = arr
      end
    end
    
    def self.get_compact_headers
      @compact_headers
    end
    
    # Directive for setting the prexisting route set at the controller level. 
    def self.pre_existing_route_set(*arr)
      if arr[0].is_a?(Array)
        @pre_existing_rs = arr[0] 
      else
        @pre_existing_rs = arr
      end
    end
    
    def self.get_pre_existing_route_set
      @pre_existing_rs
    end
    
    def self.authenticate_requests(*m)
      @auth_methods = m  
    end
    
    def self.get_authenticate_requests
      @auth_methods  
    end
    
    def self.authenticate_proxy_requests(*m)
      @p_auth_methods = m  
    end
    
    def self.get_authenticate_proxy_requests
      @p_auth_methods  
    end
    #---------------------------------------------------------------------------
    
    
    def name
      self.class.name
    end
    
    @@slog = SipLogger['siplog::sip_basecontroller']

    def logi(m)
      @@slog.info("[#{name}] "+m) if @@slog.info?
    end
    
    def logd(m)
      @@slog.debug("[#{name}] "+m) if @@slog.debug?
    end
    
    def logw(m)
      @@slog.warn("[#{name}] "+m) if @@slog.warn?
    end
   
    def loge(m)
      @@slog.error("[#{name}] "+m) if @@slog.error?
    end
    
    def logf(m)
      @@slog.fatal("[#{name}] "+m) if @@slog.fatal?
    end
   
   # start method
   
    def start
      @@slog.debug("Nothing to start") if @@slog.debug?
      return false
    end
    
   # Response handling
   
    def on_response(session)
      case session.iresponse.code
      when 100
        on_trying_res(session)
      when 101..199
        on_provisional_res(session)
      when 200..299
        on_success_res(session)
      when 300..399
        on_redirect_res(session)
      when 400..699
        on_failure_res(session)
      else
        unknown_response(code)
      end    
    end
    
    
    def on_trying_res(session)
      request_specific_response_dispatch(session, "on_trying_res")
    end
    
    def on_provisional_res(session)
      request_specific_response_dispatch(session, "on_provisional_res")
    end
    
    def on_success_res(session)
      request_specific_response_dispatch(session, "on_success_res")
    end
    
    def on_failure_res(session)
      request_specific_response_dispatch(session, "on_failure_res")
    end  
    
    def on_redirect_res(session)
      request_specific_response_dispatch(session, "on_redirect_res")
    end
    
    def on_custom_msg(session, custom_msg)
    end
    
    def unknown_response(code)
      @@slog.error("I do not handle response with code #{code}") if @@slog.error?
    end
   
    # response_method is the string "on_success_res" etc.
    def request_specific_response_dispatch(session, response_method)
      request_m = session.iresponse.get_request_method.downcase
      handler = (sprintf("%s_for_%s", response_method, request_m)).to_sym
     
      self.send(handler, session) if self.respond_to?(handler)
    end
    
    # Request handling
    # 
     
    
    #- Interestingly the benchmark for direct call, m.call and send are
    #       user     system      total        real
    #   4.726000   0.000000   4.726000 (  4.757000)
    #   6.810000   0.030000   6.840000 (  6.870000)
    #   5.027000   0.000000   5.027000 (  5.027000)
    # So I am continuing with send mechanism
    # But perhaps it is still OK to return a boolean from here as we may use it
    # for some other purposes.
    def on_request(session)
      @@slog.debug("In base_controller on_request for call #{session.call_id}") if @@slog.debug?
      m = ("on_" + session.irequest.method.downcase).to_sym
      return self.send(m, session)
    end 
   
   
    def on_media_event(session)
      if session.imedia_event.class == Media::SmReply
        self.on_media_reply(session)
      else  
        case session.imedia_event.event
        when 'AUDIOSTARTED'
          self.on_media_connected(session)
        when 'AUDIOSTOPPED'
          self.on_media_disconnected(session)
        when 'DTMFRECEIVED'
          self.on_media_dtmf_received(session)
        when 'VOICE_ACTIVITY_DETECTED'
          self.on_media_voice_activity_detected(session)
        when 'VOICE_ACTIVITY_STOPPED'
          self.on_media_voice_activity_stopped(session)
        end
      end  
    end
    
    
    def on_http_request(req, res, session)
      @@slog.debug("In base_controller on_request for HTTP request") if @@slog.debug?
      m = ("on_http_" + req.request_method.gsub(/-/, "_")).downcase.to_sym
      return self.send(m, req, res, session)  
    end 
    
    def on_http_res(session)
    end
    
    def on_media_voice_activity_detected(session)
    end

    def on_media_voice_activity_stopped(session)
    end

    def on_media_connected(session)
    end
    
    def on_media_disconnected(session) 
    end
    
    def on_media_dtmf_received(session)
    end

    def on_media_collected_digits(session, timeoutflag)
    end
    
    def unknown_request(m)
      @@slog.warn("I do not handle request with method #{m}") if @@slog.warn?
      return false
    end
  
    def method_missing(m, *a)
      unknown_request( m )
    end
    
    def on_timer(session, task)
    end
    
    # --- Session callbacks -----
    def no_ack_received(session)
    end
    
    def no_prack_received(session)
    end
    
    def session_being_invalidated_ok_to_proceed?(session)
      true
    end
    # -------------------------
    
     
    def create_session
      _create_session(DetachedSession, nil, nil, nil)
    end
    
    def create_udp_session(rip=nil, rp=nil, rs=nil)
      _create_session(UdpSession, rip, rp, rs)
    end
    
    def create_tcp_session(rip=nil, rp=nil, rs=nil, sock=nil)
      _create_session(TcpSession, rip, rp, rs, sock)
    end
    
    def create_tls_session(rip, rp)
    end
    
    def create_sctp_session
    end
    
    def _create_session(type, rip, rp, rs, sock=nil)
      rs ||= self.class.get_pre_existing_route_set
      s = type.new(rip, rp, rs, self.class.get_session_limit, self.specified_transport, sock)
      s.controller = self
      s.set_transaction_usage self.class.get_transaction_usage           #set controller wide usage
      s.set_transaction_timers(:Base, self.class.get_transaction_timers)  #set controller wide timers
      s.set_session_timer(self.class.get_session_timer)
      s.set_session_limit(self.class.get_session_limit)  # redundant as already set in init
      s.set_transaction_handlers(self.class.get_transaction_handlers)
      s.set_t2xx_retrans_usage(self.class.get_t2xx_usage)
      s.set_t1xx_retrans_usage(self.class.get_t1xx_retran_usage)
      s.set_t2xx_retrans_timers(self.class.get_t2xx_timers)
      s.set_t1xx_retrans_timers(self.class.get_t1xx_timers)
      s.set_header_order(self.class.get_header_order)
      s.set_compact_headers(self.class.get_compact_headers)
      s.set_session_record(self.class.get_session_record)
      s.set_behind_nat(self.class.get_behind_nat)
      s.set_realm(self.class.get_realm)
      s.emit_console = self.class.get_emit_console
      return s
    end
    
    
    # enables chaining by detecting interest early
    def interested?(initial_request)
       if self.respond_to?(("on_" + initial_request.method.downcase).to_sym)
         @@slog.debug("Yes I #{name} is interested") if @@slog.debug?
         return true
       else
         @@slog.debug("No I #{name} is not interested") if @@slog.debug?
         return false
       end
    end
    
    def interested_http?(http_req)
      if self.respond_to?(("on_http_" + http_req.request_method.gsub(/-/, "_")).downcase.to_sym)
         @@slog.debug("Yes I #{name} is interested") if @@slog.debug?
         return true
       else
         @@slog.debug("No I #{name} is not interested") if @@slog.debug?
         return false
       end  
    end
    
    # Returns a transport specified for the controller in the form
    # [ip, port, transport] where transport is optional and if 
    #  present can be "UDP" or "TCP". 
    # While sending the message, this preferred transport will be used
    # and on receiving the controller will be invoked only if the message
    # is received on this transport. 
    # Defining controllers can thus control which transport they are bound 
    # to. If not present a default transport, based upon the transport 
    # selection procedure is assigned to the controller. 
    def specified_transport
      nil   
    end
    
    # returns an integer indicating the position in order array as used in 
    # controller selection. -1 indicates to disregard this value. This if present
    # supercedes the order.yaml. This allows for ordering inline controllers. 
    def order
      -1
    end
    
    def registration_store
      SIP::Locator[:RegistrationStore]
    end
    
    
    # The dialog info store, keeps track of AOR => ["call_id;local_tag;remote_tag",..]
    # for the AOR belonging to the UA.
    def dialog_store
      SIP::Locator[:DialogInfoStore] 
    end
    
    def password_store
      SIP::Locator[:PasswordStore]
    end
    
    private :_create_session
    
  end

end
