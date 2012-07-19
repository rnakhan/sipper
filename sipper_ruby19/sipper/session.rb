require 'transport/udp_transport'
require 'transport/transport_and_route_resolver'
require 'util/message_fill'
require 'sip_logger'
require 'util/sipper_util'
require 'util/locator'
require 'util/validations'
require 'util/digest/digest_authorizer'
require 'sipper_configurator'
require 'response'
require 'request'
require 'session_manager'
require 'monitor'
require 'session_recorder'
require 'transaction/transaction'
require 'transaction/invite_client_transaction'
require 'transaction/invite_server_transaction'
require 'transaction/non_invite_client_transaction'
require 'transaction/non_invite_server_transaction'
require 'test_completion_signaling_helper'
require 'ostruct'
require 'rubygems'
gem 'facets', '= 1.8.54'
require 'facets/more/synchash'
require 'ruby_ext/snapshot'
require 'session_state/dialog_routes'
require 'b2bua_session_mixin'
require 'media/sipper_media_event'
require 'media/sipper_media_client'
require 'media/sipper_offer_answer'
require 'sdp/sdp'
require 'sdp/sdp_parser'
require 'sdp/sdp_generator'
require 'custom_message'
require 'registration'
require 'xml_generator/xml_doc_generator'
require 'sipper_http/sipper_http_servlet_request_wrapper'
require 'sipper_http/sipper_http_servlet'
require 'yaml'
require 'util/multipart/mime_multipart'
require 'util/multipart/multipart_parser'
require 'isup/isup'
require 'isup/isup_parser'

class Session
  include SipLogger
  include SipperUtil
  include SIP::Validations
  include B2buaSessionMixin

  attr_accessor :transport, :local_tag, :remote_tag, :prack_seq, :local_cseq, :remote_cseq,
  :call_id, :our_contact, :max_fwd,  :local_uri, 
  :remote_uri, :rip, :rp, :tp_flags, :imessage, :irequest, :iresponse, :imedia_event,
  :session_map, :session_key, :half_dialog_key, :controller, :use_transactions, :use_ict, 
  :use_nict, :use_ist, :use_nist, :session_timer, :session_limit, :tmr_hash,
  :use_2xx_retrans, :use_1xx_retrans, :t2xx_retrans_timers, :t1xx_retrans_timers, 
  :dialog_routes, :force_update_session_map, :reliable_1xx_status, :ihttp_response, 
  :subscriptionMap, :name, :offer_answer, :registrations, :behind_nat, :realm, 
  :dtmf_collected_digits, :emit_console, :detached_session
  
  class SubscriptionData
    attr_accessor :key, :timer, :source, :event, :event_id, :state, :method
  end
  
  snap_fields :@dialog_routes_snap, :@remote_tag, :@remote_uri, :@state
  
  # todo check if there ever would be a case of receiving messages from 
  # different transports for the same session.
  # Yes it is possible. UDP to TCP or TLS or back  to UDP etc.
  def initialize(*tipportrsl)
    @ilog = logger
    @timer_helper = SIP::Locator[:Sth]
    @timer_list = []
    @local_tag = nil
    @remote_tag = nil
    #todo fix the local_tag and local_cseq story for R/R
    @local_cseq = 0
    @prack_seq = 10
    @local_cseq_before_send = nil # this is set once when a request is created and reset on send
    @remote_cseq = 0
    @call_id = nil
    @our_contact = nil
    @max_fwd = 70
    @local_uri = nil          #"From" of out requests and To of out responses 
    @remote_uri = nil         #"To" of out requests and From for out responses
    @transport = tipportrsl[0] 
    @rip = tipportrsl[1]
    @rp = tipportrsl[2]
    @tp_flags = 0
    @attr_hash = {}
    @session_recorder = nil
    @session_record = nil
    @last_sent_request = nil
    @last_sent_invite = nil
    @pending_cancels = {} # keyed on txn key and value is cancel message
    @cancellable_txns = []
    @session_queue = []
    @sq_lock = ["free"]  #inuse or free, array because we want to keep the same object as we are mixing in a monitor
    @sq_lock.extend(MonitorMixin)
    # set the config for transaction usage
    set_transaction_usage SipperConfigurator[:SessionTxnUsage]
    @tmr_hash = {}  # a hash of hash of transaction timer values for each type of Txns
    SIP::Transaction::Transactions.each do |tname|
      @tmr_hash[tname] = {}
    end
    @session_timer = SipperConfigurator[:SessionTimer]
    @session_limit = SipperConfigurator[:SessionLimit]
    @session_life_so_far = 0
    @transactions = SyncHash.new  # the total transcations of this session
    @transaction_handlers = {}  # the name of transaction handler classes, keyed with types.
    @use_2xx_retrans =  SipperConfigurator[:T2xxUsage]  # boolean
    @use_1xx_retrans =  SipperConfigurator[:T1xxUsage]  # boolean
    @reliable_1xx_status = false
    @t2xx_retrans_timers = {:Start=>SIP::Transaction::T1, 
      :Cap=>SIP::Transaction::T2,
      :Limit=>(64*SIP::Transaction::T1)}
    @t2xx_retrans_timers = @t2xx_retrans_timers.merge SipperConfigurator[:T2xxTimers] if SipperConfigurator[:T2xxTimers] # 3 timer settings for 2xx retransmission
    
    @t1xx_retrans_timers = {:Start=>SIP::Transaction::T1, 
      :Limit=>(64*SIP::Transaction::T1)}
    @t1xx_retrans_timers = @t1xx_retrans_timers.merge SipperConfigurator[:T1xxTimers] if SipperConfigurator[:T1xxTimers] # 2 timer settings for 1xx retransmission
    
    @dialog_routes = DialogRoutes.new(tipportrsl[3])
    @session_limit = tipportrsl[4] if tipportrsl[4]
    @pending_response_queue = Queue.new
    @subscriptionMap = {}
    @state = ["initial"]
    @user_defined_state = false
    _schedule_timer_for_session(:session_limit, @session_limit)
    @offer_answer = Media::SipperOfferAnswer.new(self) 
    @behind_nat = SipperConfigurator[:BehindNAT] || false
    @dtmf_collect_till = nil
    @dtmf_collected_digits = ""
    @dtmf_collect_timer = nil
    # detached session is defined as the one which does not have a session
    # whose transport, ip and port has been fixed 
    @detached_session = !(@transport && @rip && @rp)
  end
  
  def get_state_array
    @state  
  end
  
  def last_state
    @state[-1]
  end
  
  def set_state(state)
    @state = [state]
    @user_defined_state = true
  end
  
  
  def set_behind_nat(bh)
    @behind_nat = bh if bh  
  end
  
  def remote_target
    @dialog_routes.get_ruri_and_routes[0]
  end
  
  def remote_target=(rt)
    @dialog_routes.remote_target = rt
  end
  
  def [](k)
    @attr_hash[k]
  end
  
  def []=(k,v)
    @attr_hash[k] = v
  end
  
  
  def _fixed_local_tag(ftag_from_msg=nil)
    unless @local_tag
      if ftag_from_msg && ftag_from_msg != "_PH_LCTG_"
        @local_tag = ftag_from_msg
        return @local_tag  
      end
      unless @remote_tag
        @local_tag = "2"
      else
        @local_tag = @remote_tag+"1"
      end
    end
    @local_tag
  end
  
  def send(msg)
    # todo: as performance improvement set only when needed. 
    unless msg.class < Message
      err_msg = "Message is not a SIP message #{msg}" 
      log_and_raise  err_msg, ArgumentError
    end
    
    # A final check to see if any route headers were pushed by the controller on the initial
    # request and here we 
    # adjust the request uri and routes one last time only for initial requests. 
    if msg.class == Request && msg.initial
      rrt = @dialog_routes.get_ruri_and_routes_for_pushed_routes(msg)
      msg.uri = rrt[0] if rrt[0]
      msg = _add_route_headers_if_present(msg, rrt)
    end
    
    _check_transport_and_destination(msg)
    unless @transport && @rip && @rp
      err_msg = "Cannot send message, as transport is not properly set #{msg}" 
      log_and_raise  err_msg, RuntimeError
    end
    case msg
    when Request 
      send_request(msg)
    when Response
      send_response(msg)
    end 
  end    
  
  
  def send_request(msg)
    if SipperConfigurator[:ProtocolCompliance] == 'strict'
      msg.from.tag = '_PH_LCTG_' unless msg.from.tag
    end
    @local_uri, @remote_uri = begin 
      log_and_raise "Cannot send CANCEL as no response received so far" unless _check_cancel_state(msg) if (msg.method == "CANCEL" && SipperConfigurator[:ProtocolCompliance]=='strict')
      @ilog.debug("This is a request and is initial "+msg.initial.to_s) if @ilog.debug?
      SipperUtil::MessageFill.fill(msg, :lctg=>_fixed_local_tag(msg.from.tag).to_s)
      if msg.initial 
        _increment_local_cseq  
        SipperUtil::MessageFill.fill(msg, :lcnts=>@local_cseq.to_s,:lcntr=>@remote_cseq.to_s, 
        :gcnt=>SipperUtil::Counter.instance.next.to_s, :rnd=>SipperUtil.trand,
        :lip=>@transport.ip, :lp=>@transport.port.to_s, 
        :rip=>@rip, :rp=>@rp.to_s, :trans=>@transport.tid)
        
        self.remote_target = msg.uri
      end
      if ((SipperConfigurator[:ProtocolCompliance]=='strict') &&
       (@local_cseq_before_send) && 
       (@local_cseq_before_send+1 != @local_cseq))
        @local_cseq -= 1  # one step back 
        log_and_raise "The CSeq has increased by more than one, you may have created but not sent a request"    
      end
      @max_fwd = msg.max_forwards.to_s.to_i
      @last_sent_request = msg
      if (msg.method == "INVITE")
        @last_sent_invite = msg
      end
      [msg.from.to_s, msg.to.to_s]
    end
    @local_tag = msg.from.tag if msg.from.tag
    @remote_tag = msg.to.tag if msg.to.tag
    
    
    # todo this is where we will look for 1300 size and flip over the transports and modify Vias
    # we will have to re-write our Via, so do a pop_via and a push_via and continue to send message
    # in the transport layer we will once again look for filling up the values. Also keep the 
    # popped via such that if sending of message fails then we revert back to popped via. 
    # Same thing needs to be done for Contact and also Record-Route if proxy
    # 
    if msg.method == "INVITE" 
      if self.use_ict
        # check for existing transactions before sending re-invite
        # 3261 14.1
        # If there is an ongoing INVITE client transaction, the TU MUST wait until the 
        # transaction reaches the completed or terminated state before initiating the new INVITE.
        # And
        # If there is an ongoing INVITE server transaction, the TU MUST wait until the 
        # transaction reaches the confirmed or terminated state before initiating the new INVITE.
        if !msg.initial && SipperConfigurator[:ProtocolCompliance]=='strict'
          @transactions.values.each do |txn|
            if txn.transaction_name == :Ict
              unless ["IctMap.Completed", "IctMap.Terminated"].include? txn.state    
                rollback_to_unsent_state
                log_and_raise "Another ICT #{txn} in progress, cannot send re-INVITE"
              end
            elsif txn.transaction_name == :Ist
              unless ["IstMap.Confirmed", "IstMap.Terminated", "IstMap.Finished"].include? txn.state
                rollback_to_unsent_state    
                log_and_raise "Another IST #{txn} in progress, cannot send re-INVITE"
              end
            end    
          end
        end
        branch = msg.via.branch
        klass = @transaction_handlers[:Ict] || @transaction_handlers[:Base]
        txn_handler = klass.new if klass
        ict = SIP::Transaction::InviteClientTransaction.new(self, branch, txn_handler, 
          transport, @tp_flags, (self.respond_to?(:sock) ? self.sock : nil))
        k = nil
        v = nil
        @tmr_hash[:Ict].each_pair {|k,v| ict.send("#{k}=".to_sym, v) }  #check if sym required
        msg.transaction = ict
        @transactions[branch] = ict
      end
    elsif msg.method == "ACK"
      # nothing special because ict txn is already terminated
    else
      if self.use_nict
        branch = msg.via.branch
        klass = @transaction_handlers[:Nict] || @transaction_handlers[:Base]
        txn_handler = klass.new if klass
        nict = SIP::Transaction::NonInviteClientTransaction.new(self, branch, txn_handler, 
          transport,  @tp_flags, (self.respond_to?(:sock) ? self.sock : nil))
        k = nil
        v = nil  
        @tmr_hash[:Nict].each_pair {|k,v| nict.send("#{k}=".to_sym, v) }  #check if sym required
        msg.transaction = nict
        if msg.method == "CANCEL"
          ctx = @transactions[branch]
          @ilog.debug("Sending CANCEL found a Ctx #{ctx} for branch #{branch}") if @ilog.debug?
          if ctx 
            ctx.cancel_ctxn = nict # ict or even nict
          else
            @transactions[branch] = nict  # in the unlikely event of no ctx
          end
        else
          @transactions[branch] = nict
        end
      end
    end
    @local_cseq_before_send = nil unless msg.method == "ACK" || msg.method == "CANCEL"
    @offer_answer.handle_outgoing_request(msg) if @offer_answer
    _send_common(msg)
  end
  
  
  # 13.3.1.4
  # Once the response has been constructed, it is passed to the INVITE server transaction.  
  # Note, however, that the INVITE server transaction will be destroyed as soon as it 
  # receives this final response and passes it to the transport.  Therefore, it is 
  # necessary to periodically pass the response directly to the transport until the ACK arrives.  
  # The 2xx response is passed to the transport with an interval that starts at T1 seconds 
  # and doubles for each   retransmission until it reaches T2 seconds (T1 and T2 are defined 
  # in Section 17).  Response retransmissions cease when an ACK request for the response 
  # is received.  This is independent of whatever transport protocols are used to send 
  # the response .
  # Since 2xx is retransmitted end-to-end, there may be hops between UAS and UAC that are UDP.  
  # To ensure reliable delivery across these hops , the response is retransmitted 
  # periodically even if the transport at the UAS is reliable.
  # If the server retransmits the 2xx response for 64*T1 seconds without receiving an ACK, 
  # the dialog is confirmed, but the session SHOULD be terminated.  This is accomplished 
  # with a BYE, as described in Section 15.
  
  def send_response(msg, check_txn=true)
    if (@reliable_1xx_status == true && msg.get_request_method == "INVITE")
      @ilog.debug("Adding response message to pending queue as Reliable provision is in progress.") if @ilog.debug?
      @pending_response_queue << msg
      @pending_response_queue << check_txn
      return
    end
    
    @offer_answer.handle_outgoing_response(msg) if @offer_answer

    @local_uri, @remote_uri = begin 
      [msg.to.to_s, msg.from.to_s]
    end
    
    @local_tag = msg.to.tag if msg.to.tag
    @remote_tag = msg.from.tag if msg.from.tag
    
    if check_txn
      txn = @transactions[msg.via.branch] if msg.via
      if txn
        if msg.get_request_method != "CANCEL"
          @ilog.debug("Found transaction for branch #{msg.via.branch} giving it the response") if @ilog.debug?
          msg.transaction = txn
        end      
      end
    end
    
    
    _send_common(msg)
    
    if ((SipperUtil::SUCC_RANGE.include?msg.code) && (msg.get_request_method=="INVITE") && @use_2xx_retrans)
      @ok_to_retrans_2xx = true
      @two_xx = OpenStruct.new
      @two_xx.response = msg
      @two_xx.tp_flags = @tp_flags
      rd = get_response_destination(msg)
      @two_xx.rip = rd[1]
      @two_xx.rp = rd[2]
      @current_t2xx = @t2xx_retrans_timers[:Start]
      _schedule_timer_for_session(:t2xx_timer, @current_t2xx)
      _schedule_timer_for_session(:t2xx_limit_timer, @t2xx_retrans_timers[:Limit])
      @ilog.debug("Started the 2xx retransmission timer for #{self}") if @ilog.debug?
    end 
    if ((SipperUtil::RPROV_RANGE.include?msg.code) && (msg.get_request_method=="INVITE") && msg.rseq)
      @reliable_1xx_status = true
      @ok_to_retrans_1xx = true
      @one_xx = OpenStruct.new
      @one_xx.response = msg
      @one_xx.tp_flags = @tp_flags
      rd = get_response_destination(msg)
      @one_xx.rip = rd[1]
      @one_xx.rp = rd[2]
      @current_t1xx = @t1xx_retrans_timers[:Start]
      @timer_helper.cancel_timer(@active_1xx_timer) if @active_1xx_timer

      if @use_1xx_retrans
        @active_1xx_timer = _schedule_timer_for_session(:t1xx_timer, @current_t1xx)
      end
      _schedule_timer_for_session(:t1xx_limit_timer, @t1xx_retrans_timers[:Limit])
      @ilog.debug("Started the 1xx retransmission timer for #{self}") if @ilog.debug?
      @last_sent_reliable_response = msg
    end 
    
    if (@reliable_1xx_status == true && msg.get_request_method == "PRACK")
      unless @active_1xx_timer && !@active_1xx_timer.canceled?
        @reliable_1xx_status = false
      
        if(@pending_response_queue.length >= 2)
          msgval = @pending_response_queue.pop
          chkval = @pending_response_queue.pop
          send_response(msgval, chkval)
        end
      end
    end
  end
  
  def _send_common(msg)
    @call_id = msg.call_id.to_s unless @call_id
    @our_contact = msg.contact.to_s if msg.contact
    @ilog.debug("In send_common @local_uri=#{@local_uri.to_s}, @remote_uri=#{@remote_uri.to_s}, @call_id=#{@call_id.to_s}")if @ilog.debug?
    raise StandardError if transport.nil? 
    # Now set the content length
    msg.update_content_length()
    SessionManager.add_session self, ((msg.class == Response) && (SipperUtil::SUCC_RANGE.include?msg.code))
    @ilog.debug("Session map is #{@session_map}") if @ilog.debug?
    if @header_order_arr
      msg.header_order = @header_order_arr   
    end
    if @compact_header_arr
      msg.compact_headers = @compact_header_arr
    end
    # now add a custom header to trace back message to session
  
    msg.p_sipper_session = (self.name || self.to_s) if SipperConfigurator[:ShowSessionIdInMessages]
    if msg.transaction
      msg.transaction.txn_send msg
      m_s = msg.transaction.msg_sent
    else 
      if msg.is_request?
        rd = get_request_destination()
      elsif msg.is_response?  
        rd = get_response_destination(msg)
      end
      if self.respond_to?(:sock)
        sock = self.sock
      else
        sock = nil
      end
      m_s = transport.send(msg, @tp_flags, rd[1], rd[2], sock)
      @ilog.debug("Now record the outgoing message from session") if @ilog.debug?
      _do_record_sip("out", msg, m_s)
    end
    msg
  end
  
  #-- callbacks from Ict into TU (TU callbacks)
  def transaction_transport_err(txn)
    # todo simulate a 503 response
  end
  
  #++
  
  # The timeout happens for IST on TimerH(completed state) and TimerI(confirmed state) expiry
  # For ICT it happens for TimerB expiry when 408 is to be simulated
  # 
  # NICT does not send 408 as per RFC 4320 
  # 4.2. Action 2
  # A transaction-stateful SIP element MUST NOT send a response with
  # Status-Code of 408 to a non-INVITE request. As a consequence, an
  # element that cannot respond before the transaction expires will not
  # send a final response at all.
  # But this is a notification from the transaction to the TU and onwards to 
  # the controller. 
  def transaction_timeout(txn)
    if (txn.transaction_name == :Ict || txn.transaction_name == :Nict)
      req = txn.message
      r = Response.create(408, "Transaction Timeout")
      r.local = true
      @ilog.debug("In timeout, response now is #{r} and calling copy with request #{req}") if @ilog.debug?
      r.copy_from(req, :call_id, :cseq, :via, :to, :from) unless req.nil?
      # note this thread is actually worker thread and not timer thread as
      # we had queued this timer on the transport queue. 
      @ilog.debug("Now sending 408 response locally for consumption to #{self}") if @ilog.debug?
      self.on_message(r)
    end  
    
  end
  
  def transaction_cleanup(txn)
    @transactions.delete txn.branch_id
  end
  
  def transaction_wrong_state(txn)
    # todo simulate a 503 response
  end
  
  # The rip and rp are set by looking at the dialog state, remote target
  # route headers etc. However, if it cannot be ascertained from the 
  # message (like name instead of IP/port in RURI or Route) then we default
  # to the rp and rip provided at the time of session creation.
  def get_request_destination
    [@transport, @rip, @rp]  
  end
  
 
  # From RFC 3581
  #   When a server attempts to send a response, it examines the topmost
  #   Via header field value of that response.  If the "sent-protocol"
  #   component indicates an unreliable unicast transport protocol, such as
  #   UDP, and there is no "maddr" parameter, but there is both a
  #   "received" parameter and an "rport" parameter, the response MUST be
  #   sent to the IP address listed in the "received" parameter, and the
  #   port in the "rport" parameter.  The response MUST be sent from the
  #   same address and port that the corresponding request was received on.
  #   This effectively adds a new processing step between bullets two and
  #   three in Section 18.2.2 of SIP 3261
  def get_response_destination(res)
    if res.via
      rip = res.via.received
      if res.via.has_param?(:rport) && res.via.transport.downcase == "udp"
        rp = res.via.rport
      else
        if x=res.via.sent_by_port
          rp = x
        else
          rp = "5060"  # not @rp here
        end
      end
    else
      rip = @rip
      rp = @rp
    end
    [@transport, rip, rp]
  end
  
  #-- TU callbacks
  #++
  
  # Create an initial request, initial request is one which does not have any existing dialog
  # state in sipper. Specifically the new initial request will not have a to tag. 
  def create_initial_request(method, uri, *rest)
    log_and_raise "Cannot send initial request as some signaling has happened" unless initial_state?
    if SipperConfigurator[:RunLoad] && SipperConfigurator[:LoadData] != nil
      unless defined? @@msg_val
        x = File.join(SipperConfigurator[:LoadData])
        @@msg_val = YAML.load(File.open(x))
        @@header_hash ={}
        @@msg_val["msg"].keys.each{ |key| @@header_hash[key]= 0}
      end
      uri = gen_hdr_for_load("uri",@@msg_val["msg"]["uri"]) if @@msg_val["msg"].has_key?("uri")
    end
    unless uri.class == URI::SipUri
      uri = URI::SipUri.new.assign(uri.to_s)
    end
    self.remote_target = uri
    rrt = @dialog_routes.get_ruri_and_routes
    r = Request.create_initial(method, rrt[0], *rest)
    if SipperConfigurator[:RunLoad] && SipperConfigurator[:LoadData] != nil
      @@msg_val["msg"].each{|key, value| eval "r.#{key}= '#{gen_hdr_for_load(key,value)}'" if key !="uri"}
    end
    r = _add_route_headers_if_present(r, rrt)
    r.via.rport = '' if @behind_nat
    if @offer_answer
      ourSdp = @offer_answer.get_sdp() 
      r.sdp = ourSdp if ourSdp!=nil    
    end  
    return r
  end
  
  def gen_hdr_for_load(header,value)
    if value.include?("[")
      start_range = (value.slice(value.index("[")+1..value.index("]")-1)).split("-")[0].to_i
      end_range = (value.slice(value.index("[")+1..value.index("]")-1)).split("-")[1].to_i
      curr_val = start_range + @@header_hash[header] 
      if  curr_val < end_range
        @@header_hash[header] = @@header_hash[header] + 1
      else
        @@header_hash[header] = 0
      end  
      curr_str = value.gsub(/\[.*-.*\]/,curr_val.to_s)
      return curr_str
    else
      return value
    end
  end  
  
  def make_new_offer(*args)
    @offer_answer.make_new_offer(*args)
  end
  
  # A helper method to create the right REGISTER request, though you can create
  # the REGISTER like any other request, this just simplifies the process.
  # Note that for 3rd party registration you may have to change the From 
  # header in REGISTER. 
  # The arguments are the URI of the REGISTRAR, AOR which is being registered
  # and an array of Contact addresses. 
  def create_register_request(uri, aor, contacts=nil)
    if (initial_state?)
      r = create_initial_request('REGISTER', uri, :from=>aor, :to=>aor)
    else
      r = create_subsequent_request('REGISTER', uri, :from=>aor, :to=>aor)
    end
    r.contact = contacts if contacts
    return r
  end
  
  def create_prack(response = @iresponse)
    @ilog.debug("Creating a prack request ") if @ilog.debug?
    _increment_local_cseq 
    h = {
      :call_id => @call_id,
      :from => @local_uri,
      :to => @remote_uri,
      :cseq => sprintf("%s PRACK", @local_cseq),
      :via => sprintf("SIP/2.0/%s %s:%s;branch=z9hG4bK-%s-%s-%s", 
      @transport.tid, @transport.ip, @transport.port.to_s, 
      @local_cseq, @remote_cseq, SipperUtil::Counter.instance.next.to_s),
      :contact => @our_contact,
      :max_forwards => @max_fwd.to_s,
      :rack => sprintf("%s %s", response.rseq, response.cseq)
    }
    
    rrt = @dialog_routes.get_ruri_and_routes
    r = Request.create_subsequent("PRACK", rrt[0], h)
    r = _add_route_headers_if_present(r, rrt)
    if (@offer_answer)
      ourSdp = @offer_answer.get_sdp() 
      r.sdp = ourSdp if ourSdp!=nil    
    end
    return r
  end
  
  def create_and_send_prack(response = @iresponse)
    req = create_prack(response)
    send(req)
  end
  
  # Create a new subsequent request. A subsequent request is created either within a dialog or for
  # cases when a request is to be sent after some request was originally sent as an example a 
  # CANCEL request. However for generating a CANCEL use helper methods for it like create_cancel or
  # create_and_send_cancel_when_ready
  def create_subsequent_request(method, increment_cseq=true)
    @ilog.debug("Creating a subsequent request for #{method} and increment_cseq flag is #{increment_cseq}") if @ilog.debug?
    log_and_raise "As call_id is not set, it is likely that no initial req was sent or recvd"  unless @call_id  
    if increment_cseq && method != "ACK" 
      _increment_local_cseq 
    end
    if (method == "ACK")
      h = {
        :call_id => @call_id,
        :from => @local_uri,
        :to => @remote_uri,
        :cseq => sprintf("%s %s", SipperUtil.cseq_number(@last_sent_invite.cseq), "ACK"),
        :via => sprintf("SIP/2.0/%s %s:%s;branch=z9hG4bK-%s-%s-%s-%s", 
        @transport.tid, @transport.ip, @transport.port.to_s, 
        @local_cseq, @remote_cseq, SipperUtil::Counter.instance.next.to_s,
        SipperUtil.trand),
        :contact => @our_contact,
        :max_forwards => @max_fwd.to_s
      }
    else
      h = {
        :call_id => @call_id,
        :from => @local_uri,
        :to => @remote_uri,
        :cseq => sprintf("%s %s", @local_cseq, method.upcase),
        :via => sprintf("SIP/2.0/%s %s:%s;branch=z9hG4bK-%s-%s-%s-%s", 
        @transport.tid, @transport.ip, @transport.port.to_s, 
        @local_cseq, @remote_cseq, SipperUtil::Counter.instance.next.to_s,
        SipperUtil.trand),
        :contact => @our_contact,
        :max_forwards => @max_fwd.to_s
      }
    end
    
    rrt = @dialog_routes.get_ruri_and_routes
    r = Request.create_subsequent(method, rrt[0], h)
    r = _add_route_headers_if_present(r, rrt)
    if (@offer_answer && (method == "ACK" || method == "UPDATE" || method == "PRACK" || method == "INVITE"))
      ourSdp = @offer_answer.get_sdp() 
      r.sdp = ourSdp if ourSdp!=nil    
    end 
    return r
  end
  
  # Challenge here is the header object of WWW-Authenticate or Proxy-Authenticate header. 
  # This is used by the UAC sending the response to challenge. 
  def create_request_with_response_to_challenge(challenge, proxy_challenge, user, passwd, lsr = @last_sent_request)
    new_req = lsr.dup
    new_req.initial = false
    _increment_local_cseq
    new_req.cseq = sprintf("%s %s", @local_cseq, lsr.method.upcase)
    new_req.via = sprintf("SIP/2.0/%s %s:%s;branch=z9hG4bK-%s-%s-%s", 
    @transport.tid, @transport.ip, @transport.port.to_s, 
    @local_cseq, @remote_cseq, SipperUtil::Counter.instance.next.to_s)
    new_req.contact = @our_contact
    if proxy_challenge
      new_req.proxy_authorization = (@da.nil? ? @da = SipperUtil::DigestAuthorizer.new : @da).create_authorization_header(challenge, proxy_challenge, user, passwd, lsr)
    else
      new_req.authorization = (@da.nil? ? @da = SipperUtil::DigestAuthorizer.new : @da).create_authorization_header(challenge, proxy_challenge, user, passwd, lsr)
    end
    
    new_req
  end
  
  # Challenge response is created by UAS when it wants to authenticate the UAC.
  def create_challenge_response(req = @irequest, proxy=false, realm=nil, 
    domain=nil, add_opaque=false, stale=false, qop=true)
    if proxy
      res = create_response(407)
    else  
      res = create_response(401)
    end
    @da = SipperUtil::DigestAuthorizer.new  if @da.nil?
    if realm.nil?
      realm = @realm || SipperConfigurator[:SipperRealm] || "sipper.com"
    end
    if proxy
      res.proxy_authenticate = 
        @da.create_authentication_header(realm, domain, add_opaque, stale, proxy, qop)
    else
      res.www_authenticate = 
        @da.create_authentication_header(realm, domain, add_opaque, stale, proxy, qop)
    end
    return res
  end
  
  
  def authenticate_request(req=@irequest)
    return [false, false] unless @da
    return [false, false] unless (req[:authorization] || req[:proxy_authorization])
    atr = req.authorization if req[:authorization]
    atr = req.proxy_authorization if req[:proxy_authorization]
    user = SipperUtil.unquote_str(atr.username)
    passwd = SIP::Locator[:PasswordStore].get(user)
    return [@da.do_authentication(req, user, passwd), true]
  end
  
  def create_response(code, phrase="SELECT", req=irequest, reliability=false)
    log_and_raise "There is no request, cannot create response"  unless req
    code = Integer(code) unless code.is_a? Numeric
    if @local_uri
      if code > 100
        @local_uri << ";tag=" << _fixed_local_tag.to_s unless @local_uri =~ /;tag=/  
      end
    end
    @ilog.debug("@local_uri is now #{@local_uri.to_s}") if @ilog.debug?
    r = Response.create(code, phrase)
    @ilog.debug("Response now is #{r} and calling copy with request #{req}") if @ilog.debug?
    r.copy_from(req, :call_id, :cseq, :via, :to, :from, :record_route) unless req.nil?
    r.to = @local_uri if @local_uri
    r.contact = (@our_contact ||= sprintf("<sip:%s:%s;transport=%s>", 
    @transport.ip, @transport.port.to_s, @transport.tid)) unless code == 100
    
    if ((req.method == "SUBSCRIBE") && (code >= 200) && (code < 300))
      r.copy_from(req, :expires) unless req.nil?
      r.expires='3600' if not r[:expires]
    end
    
    if (reliability && code > 100 && code < 200)
      r.require = "100rel"
      r.rseq = sprintf("%d", @prack_seq)
      @prack_seq = @prack_seq + 1
    end
    
    if req.method == "REGISTER" && @registrations && (code >= 200) && (code < 300)
      r.copy_from(req, :path) 
      r.contact = nil
      @registrations.each do |data|
        r.add_contact(data.contact_uri)
        r.contacts[-1].expires = data.expires
      end
      r.format_as_separate_headers_for_mv(:contact)    
    end
    #@ilog.debug("Response now is #{r}") if @ilog.debug?
    if @offer_answer
      ourSdp = @offer_answer.get_sdp()
      r.sdp = ourSdp if (ourSdp!=nil && (code==200||reliability))    
    end
    return r
  end
  
  # A simple operation to create and send the response to the request received
  # todo automatically look up reason phrases
  def respond_with(code, req=irequest, phrase=nil)
    send(create_response(code, phrase, req))
  end
  
  
  def respond_reliably_with(code, req=irequest, phrase=nil)
    raise ArgumentError, "Can only be used for provisional responses" if code < 101 || code > 200 
    send_response(create_response(code,  phrase, req, true))
  end
  
  # A simple operation to create and send a request, initial or subsequent as the case
  # may be.
  def request_with(*args)
    method = args[0].downcase
    if(method == "cancel")
      return create_and_send_cancel_when_ready
    end
    
    if(method == "ack")
      return create_and_send_ack
    end
    
    if (initial_state?)
      send(create_initial_request(*args))
    else
      send(create_subsequent_request(*args))
    end
  end
  
  
  def initial_state?
    @local_cseq+@remote_cseq == 0  
  end
  
  # todo check for strict / lax operation waiting for prov. creating only for the INVITE 
  # request etc.
  def create_cancel(lsr = @last_sent_invite)
    log_and_raise "Cannot create CANCEL as no request was sent so far"  unless lsr 
    rrt = @dialog_routes.get_ruri_and_routes
    r = Request.create_subsequent("CANCEL", rrt[0], :cseq => sprintf("%s %s", SipperUtil.cseq_number(lsr.cseq), "CANCEL") )
    r.copy_from(lsr, :call_id, :from, :to, :via, :contact, :max_forwards, :route)
    r = _add_route_headers_if_present(r, rrt)
  end
  
  def create_and_send_cancel_when_ready(lsr = @last_sent_invite)
    lsr = @last_sent_request unless lsr
    c = create_cancel(lsr)
    if _check_cancel_state(c)
      send(c)
    else
      @pending_cancels[lsr.txn_id] = c
    end
    return c
  end
  
  # To be called by controller to generate an ACK for 2xx response.  
  #13.2.2.4
  #The UAC core MUST generate an ACK request for each 2xx received from the transaction layer.  
  #The header fields of the ACK are constructed in the same way as for any request sent within 
  #a dialog (see Section 12) with the exception of the CSeq and the header fields related to authentication.  
  #The sequence number of the CSeq header field MUST be the same as the INVITE being acknowledged, but the CSeq 
  #method MUST be ACK.  The ACK MUST contain the same credentials as the INVITE.  
  #If the 2xx contains an offer (based on the rules above), the ACK MUST
  #carry an answer in its body.  If the offer in the 2xx response is not   acceptable, the 
  #UAC core MUST generate a valid answer in the ACK and then send a BYE immediately .
  # Once the ACK has been constructed, the procedures of [4] are used to determine the destination address, 
  # port and transport.  However, the request is passed to the transport layer directly for transmission, 
  # rather than a client transaction.  This is because the UAC core handles retransmissions of the ACK, 
  # not the transaction layer.  The ACK MUST be passed to the client transport every time a   
  # retransmission of the 2xx final response that triggered the ACK arrives.
  
  def create_2xx_ack
    #todo ACK must have the same credentials as INVITE.
    ack = create_subsequent_request("ACK", false)
  end
  
  
  # Provided such that it can be used by controllers those are not using the transactions, otherwise this
  # method is invoked from the ICT. 
  # 17.1.1.3
  # The ACK request constructed by the client transaction  MUST contain values for the Call-ID, From, 
  # and Request-URI that are equal to the values of those header fields in the request passed to the 
  # transport by the client transaction (call this the "original request" ).  The To header field in the 
  # ACK MUST equal the To header field in the response being acknowledged, and therefore will usually 
  # differ from the To header field in the original request by the addition of the   tag parameter.  
  # The ACK MUST contain a single Via header field, and this MUST be equal to the top Via header field 
  # of the original request.  The CSeq header field in the ACK MUST contain the same value for the sequence 
  # number as was present in the original request, but the method parameter MUST be equal to "ACK".
  # If the INVITE request whose response is being acknowledged had Route header fields, those header 
  # fields MUST appear in the ACK.  This is to ensure that the ACK can be routed properly through 
  # any downstream stateless proxies.
  
  def create_non_2xx_ack(invite=@last_sent_invite, response=@iresponse)
    h = {
      :to => response.to.to_s,
      :cseq => sprintf("%s %s", SipperUtil.cseq_number(invite.cseq),"ACK")
    }
    ack = Request.create_subsequent("ACK", invite.uri, h)
    ack.copy_from(invite, :call_id, :from, :via, :route, :contact, :max_forwards)
    ack
  end
  
  # To be used only by the controllers on receipt of a response which will be used to figure out if
  # the ACK is for 2xx or non-2xx. If it is required to generate an ACK to a response received previously
  # (not the latest response)
  # then create the ACK using the appropriate method (create_2xx_ack or create_non_2xx_ack) and then send
  # it using session.send
  # 
  def create_and_send_ack
    send(create_ack)
  end
  
  
  def create_ack
    if SipperUtil::SUCC_RANGE.include?@iresponse.code
      a = create_2xx_ack
    else
      if use_ict
        if SipperConfigurator[:ProtocolCompliance]=='strict'
          log_and_raise "As InviteClientTransaction is in use, you MUST not send non-2xx ACK from here"
        else
          @ilog.warn("As InviteClientTransaction is in use, you should not send non-2xx ACK from here") if @ilog.warn?
        end
      end
      a = create_non_2xx_ack
    end
    return a
  end
  
  
  # The media attributes set here shall be used in the next 
  # request or response sent from the controller.
  # The argument is an attribute hash and can take the form
  # set_media_attributes(:codec=>["G711U", "DTMF"] :type=>"SENDONLY", :play=>{:file=><file_name>})
  # set_media_attributes can be called any number of times, as soon as 
  # ":codec" can be from of G711U, G711A or DTMF and will be in the form of an array and 
  #          there may be more that one value for it. This can be added or removed at a later
  #          time with a new set_media_attributes() invocation. If a new codec is added 
  #          then the earlier codec should still be listed in the array. Absense of codec
  #          from the list would mean that it is being withdrawn from the offers. 
  # ":type" can be one of SENDONLY or RECVONLY or SENDRECV 
  # ":play" can be hash of {file=> <file_to_play>, repeat=> true|false, duration=> <seconds>}
  # ":play_spec" can be string "PLAY [file] [duration] | PLAY_REPEAT [file] [duration] | SLEEP [duration] | file"
  # ":play_spec" can also be used to send out DTMF like "5,SLEEP 3,6,SLEEP 2,9"
  # note if play_spec is present the play attribute will be ignored
  # ":record_file" is the name of the file to record the incoming stream
  # ":remote_m_line" the selected "m" line from the remote media stream. It can also be selected as
  # the value "any" in which case the system selects the best option from the offer. 
  # ":remote_a_line" "a" line corresponding to the m line. This is an array, corresponding to
  #   the payloads. 
  # "remote_session_a_line" the "a" line (if any) from the session part of SDP.  
  # ":remote_c_line" the selected "c" line from session or media for the remote media stream
  # This function can be called repeatedly, when you send out your offer and when to received
  # an answer. 
  # As soon as media object has enough information the media is established. As an example you may have 
  # set attributes to set your prefered codec, type and what you want to play but do not have
  # the remote information as you may have just sent out the offer. So initially you will set
  # attributes with :codec, :type, :play. Then when you receive the 200 OK you may select a media line
  # of your choice and call set_attributes with :remote_m_line and :remote_c_line. 
  # Alternatively you could have selected :remote_m_line as "any" upfront and on getting answer sipper
  # could have selected the best answer from the given options. 
  def set_media_attributes(mattr)
    play_spec = mattr[:play_spec]
    dtmf_spec = mattr[:dtmf_spec]
    rec_spec = mattr[:rec_spec]

    play = mattr[:play]
    unless play_spec
      if play
        play_spec = play[:repeat] ? "PLAY_REPEAT " : "PLAY "
        play_spec << play[:file] if play[:file]
        play_spec << " " << play[:duration] if play[:duration]
      end
    end

    unless rec_spec
       recfile = mattr[:record_file]
       rec_spec = recfile if recfile
    end

    if @offer_answer
      @offer_answer.setup_media_spec(play_spec, rec_spec, dtmf_spec) 
      @offer_answer.refresh_sipper_media if play_spec || rec_spec
    end
  end

  def update_dtmf_spec(mattr)
     set_media_attributes(mattr)
  end

  def update_audio_spec(mattr)
     set_media_attributes(mattr)
     #@offer_answer.refresh_sipper_media if @offer_answer
  end

  def set_dtmf_collect_spec(collect_till = "#", timeoutmsec=0)
     @dtmf_collect_till = collect_till
     @dtmf_collected_digits = ""
     @timer_helper.cancel_timer(@dtmf_collect_timer) if @dtmf_collect_timer
     @dtmf_collect_timer = nil

     if timeoutmsec > 0
       @ilog.debug("Scheduling a DTMF collect timer for #{timeoutmsec}") if @ilog.debug?
       @dtmf_collect_timer = @timer_helper.schedule_for(self, nil, nil, :dtmf_collect_timer, timeoutmsec)
       @timer_list << @dtmf_collect_timer
     end
  end
  
  
  # todo write tests for on_message, on_request, on_response when doing IT
  def on_message(r)
    @ilog.debug("session.on_message called for session #{self} and message #{r.short_to_s}") if @ilog.debug?
    @sq_lock.synchronize do
      @session_queue << r
      if @sq_lock[0] == "free"
        @sq_lock[0] = "inuse"
      else
        return
      end
    end
    msg = nil
    loop do
      @ilog.debug("Looking for a new message from session level queue") if @ilog.debug?
      @sq_lock.synchronize do
        msg = @session_queue.shift
        unless msg
          @sq_lock[0] = "free"
          return
        end
      end
      @ilog.debug("In session.on_message now processing message #{msg}") if @ilog.debug?
      case msg
      when Request
        _on_request(msg)
      when Response
        _on_response(msg)
      when SIP::TimerTask
        _on_timer(msg) unless msg.canceled?
      when Media::SipperMediaEvent
        _on_media_event(msg)
      when SipperHttp::SipperHttpResponse
        _on_http_response(msg)
      when SipperHttp::SipperHttpServletRequestWrapper
        _on_http_request(msg)
      when CustomMessage
        _on_custom_message(msg)
      end
      
    end 
  end
  
  # invoked on incoming request
  def _on_request(request)
    _update_and_check_dialog_state_on_request(request)
    @offer_answer.handle_incoming_request(request) if @offer_answer
    
    # We forward the CANCEL to the transaction being canceled only after the 
    # NIST processing of the CANCEL is over. So typically a 200/CANCEL shall precede
    # the 487/INVITE. 
    forward_cancel_to_stxn = false
    nist = nil
    stxn = nil
    
    if request.method == "PRACK"
      if request[:rack] && @last_sent_reliable_response && @last_sent_reliable_response[:rseq]
         if request.rack.header_value.strip.split(' ')[0] == @last_sent_reliable_response.rseq.header_value.strip
           @ok_to_retrans_1xx = false
           @active_1xx_timer.cancel if @active_1xx_timer
         else
           @ilog.debug("PRACK doesnt match the last sent reliable response.") if @ilog.debug?
         end
      end
    end
    
    if request.method == "INVITE"
      if self.use_ist
        branch = request.via.branch
        ist = @transactions[branch]
        if ist
          @ilog.debug("Found transaction #{ist} for branch #{request.via.branch} for INVITE retransmission") if @ilog.debug?
        else
          # one final check for equal CSeq since this is not a retransmission now and therefore 
          # must be a bad request.
          _equal_cseq_check(request) unless request.attributes[:_sipper_rejection_response]
          # check for existing invite transactions
          _check_pending_invite_txns_on_invite_in(request)unless request.attributes[:_sipper_rejection_response] 
          @ilog.debug("Not found transaction for branch #{request.via.branch} for INVITE, creating a new IST") if @ilog.debug?
          klass = @transaction_handlers[:Ist] || @transaction_handlers[:Base]
          txn_handler = klass.new if klass
          ist = SIP::Transaction::InviteServerTransaction.new(self, branch, txn_handler, transport, 
                  @tp_flags, (self.respond_to?(:sock) ? self.sock : nil))
          k = nil
          v = nil 
          @tmr_hash[:Ist].each_pair {|k,v| ist.send("#{k}=".to_sym, v) }  
          @transactions[branch] = ist
        end
        request.transaction = ist
        ist.txn_received(request)
        unless ist.consume?
          @ilog.debug("Not consuming this request #{request.method} as txn has taken care of it.") if @ilog.debug?
          return
        end
      end # ist being used
    elsif request.method == "ACK"
      txn = @transactions[request.via.branch]
      if txn
        @ilog.debug("Found transaction for branch #{request.via.branch} for ACK") if @ilog.debug?
        request.transaction = txn
        txn.txn_received(request)
        unless txn.consume?
          @ilog.debug("Not consuming this request #{request.method} as txn has taken care of it.") if @ilog.debug?
          return
        end
      else  # no transaction found, this must be a ACK for 2xx as new branch
        @ok_to_retrans_2xx = false
      end
    else  # method other than INV/ACK
      if self.use_nist
        branch = request.via.branch
        stxn = @transactions[branch]
        if request.method == "CANCEL"
          if stxn
            nist = stxn.cancel_stxn
            @ilog.debug("Found CANCEL transaction #{nist} for branch #{request.via.branch} for CANCEL retransmission") if nist if @ilog.debug?
          end
        else
          nist = stxn
          @ilog.debug("Found NIST transaction #{nist} for branch #{request.via.branch} for non-INVITE retransmission") if nist if @ilog.debug?
        end
        unless nist
          # one final check for equal CSeq since this is not a retransmission now and therefore 
          # must be a bad request, unless it is a CANCEL. 
          unless request.method == "CANCEL"
            _equal_cseq_check(request) unless request.attributes[:_sipper_rejection_response] 
          end
          @ilog.debug("Not found transaction for branch #{request.via.branch} for non-INVITE, creating a new NIST") if @ilog.debug?
          klass = @transaction_handlers[:Nist] || @transaction_handlers[:Base]
          txn_handler = klass.new if klass
          nist = SIP::Transaction::NonInviteServerTransaction.new(self, branch, txn_handler, transport, 
                   @tp_flags, (self.respond_to?(:sock) ? self.sock : nil))
          k = nil
          v = nil
          @tmr_hash[:Nist].each_pair {|k,v| nist.send("#{k}=".to_sym, v) }  
        end
        request.transaction = nist
        if request.method == "CANCEL"
          @ilog.debug("Received CANCEL found a Stx #{stxn} for branch #{branch}") if @ilog.debug?
          if stxn 
            nist.transaction_being_canceled = stxn if nist
            forward_cancel_to_stxn = true
          else
            nist.ok_to_send_481_to_cancel = true if self.use_ist && self.use_nist
            @ilog.debug("Processing CANCEL, no stx found, check if 481 is to be sent") if @ilog.debug?
          end
        else
          @transactions[branch] = nist unless stxn
        end
        nist.txn_received(request)
        unless nist.consume?
          @ilog.debug("Not consuming this request #{request.method} as txn has taken care of it.") if @ilog.debug?
          return
        end
      else  # nist not being used, but still look for IST for CANCEL
        if request.method == "CANCEL"
          branch = request.via.branch
          stxn = @transactions[branch]  # should be IST
          @ilog.debug("Received CANCEL found a Stx #{stxn} for branch #{branch}") if @ilog.debug?
          if stxn 
            forward_cancel_to_stxn = true
          else
            @ilog.debug("Processing CANCEL, no stx found, not using nist either") if @ilog.debug?
          end
        end
      end
    end
    
    # Check for the rejection response here
    if request.attributes[:_sipper_rejection_response]
      @ilog.info("Found the rejection response, sending it and not invoking controller") if @ilog.info?
      send_response(request.attributes[:_sipper_rejection_response])
      return 
    end 
    
    if request.method == "REGISTER"
      @registrations = _create_registration_object(request)  
    end
    
    if @controller
      @ilog.debug("Dispatching request to controller #{@controller.name}") if @ilog.debug?
      begin
        result = @controller.on_request(self)
      rescue Exception => e
        @ilog.error("Exception #{e} occured while request processing by controller") if @ilog.error? 
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
      @ilog.warn("#{@controller} could not process the request") if result == false && @ilog.warn?
    else
      @ilog.error("No controller associated with this session") if @ilog.error?
    end
    stxn.cancel_received(request, nist) if forward_cancel_to_stxn && stxn
  end
  
  
  def pre_set_dialog_id(r)
    @remote_tag = r.from_tag
    @call_id = r.call_id.to_s
  end
  
  # invoked on incoming response
  def _on_response(response)
    if ((SipperConfigurator[:ProtocolCompliance]=='strict') && !(response.locally_generated?))
      # check 18.1.2
      # When a response is received, the client transport examines the top Via header field value.  
      # If the value of the "sent-by" parameter in that header field value does not 
      # correspond to a value that the client transport is configured to insert 
      # into requests, the response MUST be silently discarded.
      if (transport.ip != response.via.sent_by_ip) || (transport.port.to_s != response.via.sent_by_port) && SipperConfigurator[:ProtocolCompliance] == 'strict' 
        @ilog.warn("Response via #{response.via} sent_by does not match our transport, dropping message") if @ilog.warn?
        return
      end
    end
    _update_dialog_state_on_response(response)
    @offer_answer.handle_incoming_response(response) if @offer_answer
    txn = @transactions[response.via.branch]
    if txn && !(response.locally_generated?) && response.get_request_method == "CANCEL"
      txn = txn.cancel_ctxn || txn  # for the case when NICT but not ICT in use
    end
    if (txn  && !(response.locally_generated?))
      @ilog.debug("Found transaction #{txn} for branch #{response.via.branch} giving it the response") if @ilog.debug?
      response.transaction = txn
      txn.txn_received(response)
      unless txn.consume?
        @ilog.debug("Not consuming this response #{response.code} as txn has taken care of it.") if @ilog.debug?
        return
      end
    end
    
    if response.get_request_method == "REGISTER"
      @registrations = _create_registration_object(response, false)  
    end
    
    if @controller
      begin
        @controller.on_response(self)
      rescue Exception => e
        @ilog.error("Exception #{e} occured while response processing by controller") if @ilog.error?
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
    else
      @ilog.error("No controller associated with this session") if @ilog.error?
    end
  end
  
  # On receipt of request or response
  def _on_common_sip(msg)
    if msg[:content_type] && msg.content_type.to_s =~ /sdp/   
      msg.sdp = SDP::SdpParser.parse(msg.contents, true)  if msg[:content]
    end    
    if msg[:content_type] && msg.content_type.to_s =~ /multipart/   

      msg.multipart_content = Multipart::MultipartParser.parse(msg.contents,msg.content_type)  if msg[:content]
        msg.multipart_content.get_count.times do |i|
                         if msg.multipart_content.get_bodypart(i).type == "application/sdp"

                                     msg.sdp = SDP::SdpParser.parse(msg.multipart_content.get_bodypart(i).contents,true)
                          end
		
        end

    end
    @call_id = msg.call_id.to_s
    @ilog.debug("Now record the incoming message") if @ilog.debug?
    _do_record_sip("in", msg)
  end
  
  #-------------------------------
  # Transcation handling setting
  
  def use_ict
    return @use_ict unless @use_ict.nil?
    @use_transactions
  end
  
  def use_nict
    return @use_nict unless @use_nict.nil?
    @use_transactions
  end
  
  def use_ist
    return @use_ist unless @use_ist.nil?
    @use_transactions
  end
  
  def use_nist
    return @use_nist unless @use_nist.nil?
    @use_transactions
  end
  
  def set_transaction_usage(tr_hash)
    tr_hash.each_pair { |k,v| self.__send__((k.to_s+'=').to_sym, v) } if tr_hash
  end
  
  # returns the consolidated hash of timers which can be set to the 
  # transaction in question by calling SipperUtil.hash_to_iv(@timers, txn) if @timers
  # the type of transactions can be either the names of transactions as @transation_name
  # defined in  the transaction or it can be :Base which is the override for all types of 
  # transactions. 
  def set_transaction_timers(type, tmr_hash)
    if tmr_hash
      if type == :Base
        @tmr_hash.each_key {|k| @tmr_hash[k]= tmr_hash }
      else 
        @tmr_hash[type] = @tmr_hash[type].merge(tmr_hash)
      end
    end
    #@tmr_hash.each_key {|k| puts "#{k} = #{@tmr_hash[k]}" }
  end
  
  # e.g. :Ict=>MyIctHandler, :Nict=>MyNictHandler, :Base=>CatchAllHandler
  def set_transaction_handlers(tx_hnd_hash)
    @transaction_handlers = tx_hnd_hash if tx_hnd_hash
  end
  
  def set_session_timer(val)
    @session_timer = val if val
  end
  
  def set_session_limit(val)
    @session_limit = val if val
  end
  
  
  def set_session_record(val)
    @session_record = val  
  end
  
  # boolean, whether the 2xx retransmission timer is to be used or not for
  # the UAS 
  def set_t2xx_retrans_usage(val)
    @use_2xx_retrans = val
  end
  
  def set_t1xx_retrans_usage(val)
    @use_1xx_retrans = val
  end
  
  # the hash of 3 timer values that affect 2xx retransmissions for UAS 
  # i.e {:Start=>100, :Cap=>400, :Limit=>1600} that roughly 
  # correspond with T1, T2 and 64*T1 respectively, which are also the
  # defaults.               
  def set_t2xx_retrans_timers(t_hash)
    if t_hash
      @t2xx_retrans_timers = @t2xx_retrans_timers.merge t_hash
    end
  end  
  
  def set_t1xx_retrans_timers(t_hash)
    if t_hash
      @t1xx_retrans_timers = @t1xx_retrans_timers.merge t_hash
    end
  end 
  
  # The partial or full list of headers in the order in which the message
  # is to be formatted. In the absense of this the header ordering is 
  # arbitrary. e.g.
  #   set_header_order([:from, :to, :call_id, :via])
  #   shall format the headers in the order
  #   ....
  #   From: sut <sip:service@127.0.0.1:5060>;tag=azxs21
  #   To: sipp <sip:sipp@127.0.0.1:6061>;tag=1
  #   Call-Id: 6766_112@127.0.0.1
  #   Via: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
  #   ....
  # once set this setting affects all the messages created by this session. 
  def set_header_order(arr)
    @header_order_arr = arr
  end
  #------------------------------
  
  # The headers which are required to be expressed in their compact form. 
  # e.g. 
  #   set_compact_headers [:from, :via]
  #   shall use the compact form for headers From and Via and the message shall 
  #   look like -  
  #   f: sut <sip:service@127.0.0.1:5060>;tag=azxs21
  #   To: sipp <sip:sipp@127.0.0.1:6061>;tag=1
  #   Call-Id: 6766_112@127.0.0.1
  #   v: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0
  #   
  #   In case all possible headers are required in compact form then use 
  #   [:all_headers] as the argument value. 
  #   A complete list of headers with known compact form can be obtained 
  #   from - http://www.iana.org/assignments/sip-parameters
  def set_compact_headers(arr)
    @compact_header_arr = arr
  end
  
  # public method called when the timer of this session target is fired
  def on_timer_expiration(task)
    # we treat the incoming timer task as a message to leverage
    # the session level queueing for synchronization.
    on_message(task)
  end
  
  # this is internally called when the timer is acted upon
  def _on_timer(task)
    if @invalidated
      @ilog.info("This session #{self.session_key} is invalidated, not firing timer #{task}") if @ilog.info?
      return
    end
    @ilog.debug("Timer task #{task} invoked") if @ilog.debug?
    if task.type == :app
      begin
        @controller.on_timer(self, task) if @controller
      rescue Exception => e
        @ilog.error("Exception #{e} occured while timer processing by controller") if @ilog.error?
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
    elsif task.type == :dtmf_collect_timer
      begin
         if @dtmf_collect_timer
            if task.equal?@dtmf_collect_timer
               if @controller
                 @ilog.debug("Dispatching collected digits to controller #{@controller.name}") if @ilog.debug?
                 begin
                   result = @controller.on_media_collected_digits(self, true)
                 rescue Exception => e
                   @ilog.error("Exception #{e} occured while collect digit processing by controller") if @ilog.error?
                   @ilog.error(e.backtrace.join("\n")) if @ilog.error?
                 end
                 @ilog.warn("#{@controller} could not process the media event") if result == false && @ilog.warn?
               else
                 @ilog.error("No controller associated with this session") if @ilog.error?
               end  
               @dtmf_collect_till = nil
               @dtmf_collect_timer = nil
               @dtmf_collected_digits = ""
            end
         end
      end
    elsif task.type == :subscription
      begin
        subscription = task.tid
        if subscription.state != 'active'
          return
        end
        if task.equal?subscription.timer
          if subscription.source == 'uac'
            @controller.on_subscription_refresh_timeout(self, subscription)
          else
            @controller.on_subscription_timeout(self, subscription)
          end
        end
      end
    elsif task.type == :registration
      registration = task.tid
      begin
        @controller.on_registration_expiry(self, registration)
      end   
    elsif task.type == :session
      if task.tid == :session_timer
        if @controller
          @ilog.debug("Invoking session listener for #{@controller.name}") if @ilog.debug?
          begin
            result = @controller.session_being_invalidated_ok_to_proceed?(self)
          rescue Exception => e
            @ilog.error("Exception #{e} occured while callback processing by controller") if @ilog.error?
            @ilog.error(e.backtrace.join("\n")) if @ilog.error?
          end
          if result
            @ilog.debug("#{@controller} not interested in session invalidation")  if @ilog.debug?
          else
            @ilog.debug("#{@controller} decided to increase the lifetime of session") if @ilog.debug?
            if (@session_life_so_far+@session_timer < @session_limit)
              @invalidating = false # to force the timer to start
              self.invalidate
              return
            else
              @ilog.warn("Not increasing the lifetime of session, as upper session limit reached") if @ilog.warn?
            end  
          end
        else
          @ilog.debug("No controller interested in session invalidation") if @ilog.debug?
        end
        self.invalidate(true)
      elsif task.tid == :t2xx_timer
        @ilog.debug("2xx retransmission timer fired for #{self}") if @ilog.debug?
        if @ok_to_retrans_2xx
          _do_record_sip("out", @two_xx.response, @two_xx.response.to_s)
          transport.send(@two_xx.response, @two_xx.tp_flags, @two_xx.rip, @two_xx.rp) 
          @ilog.debug("Retransmitted the 2xx response from #{self}") if @ilog.debug?
          @current_t2xx = [@t2xx_retrans_timers[:Start]*2, @t2xx_retrans_timers[:Cap]].min
          _schedule_timer_for_session(:t2xx_timer, @current_t2xx) 
        end  # still ok to retrans
      elsif task.tid == :t2xx_limit_timer
        @ok_to_retrans_2xx = false
        if @controller
          @ilog.debug("Invoking no_ack_received session listener for #{@controller.name}") if @ilog.debug?
          begin
            result = @controller.no_ack_received(self)
          rescue Exception => e
            @ilog.error("Exception #{e} occured while callback processing by controller") if @ilog.error?
            @ilog.error(e.backtrace.join("\n")) if @ilog.error?
          end
        end # if controller
      elsif task.tid == :t1xx_timer
        if task.equal?@active_1xx_timer
          @ilog.debug("1xx retransmission timer fired for #{self}") if @ilog.debug?
          if @ok_to_retrans_1xx
            _do_record_sip("out", @one_xx.response, @one_xx.response.to_s)
            transport.send(@one_xx.response, @one_xx.tp_flags, @one_xx.rip, @one_xx.rp) 
            @ilog.debug("Retransmitted the 1xx response from #{self}") if @ilog.debug?
            @current_t1xx = @current_t1xx*2
            @timer_helper.cancel_timer(@active_1xx_timer) if @active_1xx_timer
            @active_1xx_timer = _schedule_timer_for_session(:t1xx_timer, @current_t1xx) 
          end  # still ok to retrans
        else
           @ilog.debug("Ignoring invalid 1xx timer #{task}") if @ilog.debug?
        end
      elsif task.tid == :t1xx_limit_timer
        @ok_to_retrans_1xx = false
        if @controller
          @ilog.debug("Invoking no_prack_received session listener for #{@controller.name}") if @ilog.debug?
          begin
            result = @controller.no_prack_received(self)
          rescue Exception => e
            @ilog.error("Exception #{e} occured while callback processing by controller") if @ilog.error?
            @ilog.error(e.backtrace.join("\n")) if @ilog.error?
          end
        end # if controller
      elsif task.tid == :session_limit
        @ilog.info("Upper limit of session time limit reached, now invalidating #{self}") if @ilog.info?
        self.invalidate(true)
      end #type of session timer
    end   #session or app
  end
  
  
  def schedule_timer_for(tid, duration, &block)
    @ilog.debug("Scheduling an app timer #{tid} for #{duration}") if @ilog.debug?
    task = @timer_helper.schedule_for(self, tid, block, :app, duration)
    @timer_list << task
    task
  end
  
  def _schedule_timer_for_session(tid, duration, &block)
    @ilog.debug("Scheduling a session level timer #{tid} for #{duration}") if @ilog.debug?
    task = @timer_helper.schedule_for(self, tid, block, :session, duration)
    @timer_list << task
    task
  end
  
  def send_http_post_to(url, params, user=nil, passwd=nil, hdr_arr=nil, body=nil)
    SIP::Locator[:HttpRequestDispatcher].request_post(url, self, params, user, passwd, hdr_arr, body)  
  end
  
  def send_http_get_to(url, user=nil, passwd=nil, hdr_arr=nil, body=nil)
    SIP::Locator[:HttpRequestDispatcher].request_get(url, self, user, passwd, hdr_arr, body)
  end
  
  def send_http_put_to(url, user=nil, passwd=nil, hdr_arr=nil, body=nil)
    SIP::Locator[:HttpRequestDispatcher].request_put(url, self, user, passwd, hdr_arr, body)
  end
  
  # Invoked when the HTTP response is ready to be consumed
  def on_http_response(http_res)
    on_message(http_res)
  end
  
  
  def on_http_request(servlet_req_obj)
    if @controller && @controller.interested_http?(servlet_req_obj.req)
      on_message(servlet_req_obj)
    else
      SipperHttp::SipperHttpServlet.send_no_match_err(servlet_req_obj.req, servlet_req_obj.res)
    end
  end
  
  
  # Invoked when either the Sipper media response or an actual media event
  # is received.
  def on_media_event(media_evt)
    # we treat the incoming media event as a message to leverage
    # the session level queueing for synchronization.
    on_message(media_evt)  
  end
  
  def _on_media_event(media_event)
    @imedia_event = media_event

    if @controller
      @ilog.debug("Dispatching media event to controller #{@controller.name}") if @ilog.debug?
      begin
        result = @controller.on_media_event(self)
      rescue Exception => e
        @ilog.error("Exception #{e} occured while media processing by controller") if @ilog.error?
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
      @ilog.warn("#{@controller} could not process the media event") if result == false && @ilog.warn?
    else
      @ilog.error("No controller associated with this session") if @ilog.error?
    end  

    if media_event.class == Media::SmEvent
       if media_event.event == 'DTMFRECEIVED'
          if media_event.dtmf == @dtmf_collect_till
             if @controller
               @ilog.debug("Dispatching collected digits to controller #{@controller.name}") if @ilog.debug?
               begin
                 result = @controller.on_media_collected_digits(self, false)
               rescue Exception => e
                 @ilog.error("Exception #{e} occured while collect digit processing by controller") if @ilog.error?
                 @ilog.error(e.backtrace.join("\n")) if @ilog.error?
               end
               @ilog.warn("#{@controller} could not process the media event") if result == false && @ilog.warn?
             else
               @ilog.error("No controller associated with this session") if @ilog.error?
             end  
             @dtmf_collect_till = nil
             @dtmf_collect_timer = nil
             @dtmf_collected_digits = ""
          else
             @dtmf_collected_digits += media_event.dtmf
          end
       end
    end

  end
  
  def _on_http_response(http_res)
    @ihttp_response = http_res
    if @controller
      @ilog.debug("Dispatching http response to controller #{@controller.name}") if @ilog.debug?
      begin
        result = @controller.on_http_res(self)
      rescue Exception => e
        @ilog.error("Exception #{e} occured while http response processing by controller") if @ilog.error?
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
      @ilog.warn("#{@controller} could not process the http response") if result == false && @ilog.warn?
    else
      @ilog.error("No controller associated with this session") if @ilog.error?
    end  
  end
  
  def _on_http_request(servlet_req_obj)
    @ihttp_request = servlet_req_obj.req
    result = false
    if @controller
      @ilog.debug("Dispatching http request to controller #{@controller.name}") if @ilog.debug?
      begin
        result = @controller.on_http_request(servlet_req_obj.req, servlet_req_obj.res, self)
      rescue Exception => e
        @ilog.error("Exception #{e} occured while http request processing by controller") if @ilog.error?
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
      @ilog.warn("#{@controller} could not process the http request") if result == false && @ilog.warn?
    else
      @ilog.error("No controller associated with this session") if @ilog.error?
    end
  end

  def _on_custom_message(custom_msg)
    if @controller
      @ilog.debug("Dispatching custom message to controller #{@controller.name}") if @ilog.debug?
      begin
        result = @controller.on_custom_msg(self, custom_msg)
      rescue Exception => e
        @ilog.error("Exception #{e} occured while processing custom message by controller") if @ilog.error?
        @ilog.error(e.backtrace.join("\n")) if @ilog.error?
      end
      @ilog.warn("#{@controller} could not process the custom message") if result == false && @ilog.warn?
    else
      @ilog.error("No controller associated with this session") if @ilog.error?
    end
  end

  def post_custom_message(custom_msg)
     on_message(custom_msg)
  end
  
  
  def invalidate(force=false)
    if @invalidated
      @ilog.warn("This session with key #{self.session_key} is already invalidated") if @ilog.warn?
      return
    end
    
    if force
      @ilog.debug("Now invalidating the session #{self} with key #{self.session_key}") if @ilog.debug?
      @timer_list.each { |timer_task| @timer_helper.cancel_timer(timer_task)}
      @offer_answer.close if @offer_answer
      @transactions.each_value do |t| 
        @ilog.debug("Invalidating the txn #{t} in session #{self}") if @ilog.debug?
        t.invalidate
      end
      @session_recorder.save if @session_recorder
      SessionManager.remove_session self 
      @invalidated = true 
      SIP::TestCompletionSignalingHelper.signal_waiting_test(@signal_test_complete_when_invalidated) if @signal_test_complete_when_invalidated
	  else
      if @invalidating
        @ilog.info("This session with key #{self.session_key} is already scheduled for invalidation") if @ilog.info?
        return
      end
      @invalidating = true
      tmr = _schedule_timer_for_session(:session_timer, @session_timer)
      @session_life_so_far += @session_timer
      @ilog.debug("Now scheduling the session #{self.session_key} for invalidation after #{@session_timer} #{tmr}") if @ilog.debug?
    end
  end
  
  
  def record_io=(rio)
    @rio = rio
  end
  
  def do_record(msg)
    msg = SipperUtil.recordify(msg)
    _do_record_sip("neutral", msg)
  end
  
  def transaction_record(direction, msg)
    _do_record_sip(direction, msg)
  end
  
  def flow_completed_for(test_name)
    if SipperConfigurator[:RunLoad]
      SipperConfigurator[:TempCallCount] = 0 unless SipperConfigurator[:TempCallCount]
      SipperConfigurator[:TempCallCount] += 1  
      return unless SipperConfigurator[:TempCallCount] == SipperConfigurator[:NumCalls]
      SipperConfigurator[:TempCallCount] = nil
    end
    unless @invalidated
      @ilog.debug("Session not invalidated yet, setting flag signaling completion") if @ilog.debug?
      @signal_test_complete_when_invalidated = test_name.to_s
      return true
    end
    @ilog.debug("In flow_completed_for() now signaling the waiting test") if @ilog.debug?
    SIP::TestCompletionSignalingHelper.signal_waiting_test(test_name.to_s)
	SIP::Locator[:Smd].shutdown if SIP::Locator[:Smd] and !SipperConfigurator[:SipperMediaProcessReuse]
  end
  
  # The first recording will create the recording file name using in or out
  # todo will it be enough for uniqueness? 
  def _do_record_sip(direction, msg, msg_s=nil)
    @ilog.debug("record() invoked for #{direction} and #{msg.call_id.to_s}") if @ilog.debug?
    # maintain simple state in the session
    unless @user_defined_state
      if direction == "out"
        if msg.is_request?
          @state << ("sent_" + msg.method.downcase)
        elsif msg.is_response?  
          @state  << ("sent_" + msg.code.to_s)
        end
      elsif direction == "in"
        if msg.is_request?
          @state << ("received_" + msg.method.downcase)
        elsif msg.is_response?  
          @state  << ("received_" + msg.code.to_s)
        end
      end
    end
    unless @session_recorder
      @session_recorder = SessionRecorder.create_and_record(@rio, msg, msg_s, direction, @session_record, @emit_console)  
    else
      @session_recorder.record(direction, msg, msg_s, @emit_console)
    end
  rescue RuntimeError => e
    @ilog.error("Unable to record the #{msg} as recorder is closed") if @ilog.error?
  end
  
  
  def _check_cancel_state(msg)
    @cancellable_txns.include? msg.txn_id  
  end
  
  def _check_for_pending_cancel
    txn_id = @iresponse.txn_id
    @cancellable_txns << txn_id
    if pc = @pending_cancels[txn_id] 
      @pending_cancels.delete(txn_id)
      if SipperConfigurator[:ProtocolCompliance] == 'strict'
        return if @iresponse.code >= 200
      end
      send pc
    end
  end
  
  def _increment_local_cseq
    @local_cseq_before_send ||= @local_cseq
    @local_cseq += 1
    @ilog.debug "Local cseq before send set to #{@local_cseq_before_send} and @local_cseq is #{@local_cseq}" if @ilog.debug?
  end
  
  # Useful when you create a subsequent request but do not send it.
  # This resets the state to the time when the request was not created. 
  def rollback_to_unsent_state
    @local_cseq = @local_cseq_before_send if @local_cseq_before_send
    @local_cseq_before_send = nil
  end
  
  # 3261 Section 8.2
  # Note that request processing is atomic.  
  # If a request is accepted, all state changes associated with it MUST be performed.  
  # If it is rejected, all state changes MUST NOT be performed.
  # 
  # This rollback is invoked automatically when Sipper rejects the request before it invokes 
  # the controller. The controller can invoke it to rollback any dialog state if it is
  # going to reject the request or alternatively if the compliance flag is set to strict
  # this will automatically be called on request rejection. 
  # Note that the snapshot is single-depth state capture, does not save any contained
  # object's state. 
  def rollback_to_before_request_received_state(request)
    if request.session_state_snapshot
      self.restore_snapshot(request.session_state_snapshot)
      @dialog_routes.restore_snapshot(@dialog_routes_snap)
      @dialog_routes_snap = nil
      request.session_state_snapshot = nil
      @ilog.debug("Restored to previous session state for request #{request.method}") if @ilog.debug?
    else
      @ilog.debug("No state to rollback.") if @ilog.debug?
    end
  end
  
  # creates a failure response and also rolls back the session state, this is called 
  # when the request is rejected by Sipper itself. 
  def rejection_response_with(code, request)
    @ilog.info("Rejecting the request #{request.method} with a #{code}") if @ilog.info?
    r = create_response(code, "SELECT", request)
    rollback_to_before_request_received_state(request)
    return r
  end
  
  # Sometimes you create a new session but would like to continue the
  # recording process from previous session for validation purposes. 
  # This would typically be used when you drop a leg and create a new
  # one. 
  def continue_recording_from(old_session)
    @session_recorder = old_session._get_recorder
    old_session._remove_recorder
  end
  
  
  def _update_and_check_dialog_state_on_request(request)
    new_remote_cseq = SipperUtil.cseq_number(request.cseq)
    @dialog_routes_snap = @dialog_routes.take_snapshot
    request.session_state_snapshot = self.take_snapshot
    @dialog_routes.request_received(request)
    _on_common_sip(request)
    @imessage = @irequest = request
    @remote_tag = @irequest.from_tag unless @remote_tag
    @local_uri = @irequest.to.to_s
    @remote_uri = @irequest.from.to_s
    
    # RFC 3891 section 3 testing for more than one Replaces header field in an INVITE, 
    # Replaces header field in a request other than INVITE and Replaces header field and
    # another header field with contradictory semantics      
    if SipperConfigurator[:ProtocolCompliance]=='strict' && request[:replaces] 
      if (request.method != "INVITE" || request[:join] || request[:replaces].length > 1)
        request.attributes[:_sipper_rejection_response] = rejection_response_with(400, @irequest)
      end  
      return false
    end
    # 3261 12.2.2 testing for < because a retransmission will have same sequence, as will be 
    # ACK and CANCEL
    if SipperConfigurator[:ProtocolCompliance]=='strict' && 
      new_remote_cseq < @remote_cseq
      if @irequest.method == "ACK"
        @ilog.debug("Dropping an ACK for an out of CSeq rejected request") if @ilog.debug?
      else
        request.attributes[:_sipper_rejection_response] = rejection_response_with(500, @irequest)
        @ilog.debug("Rejected the request #{@irequest.method} for out of CSeq") if @ilog.debug?
      end
      return false
    end
    request.attributes[:_sipper_old_cseq] = @remote_cseq # save old for later check
    @remote_cseq = new_remote_cseq
    
    if request.method == 'NOTIFY'
      if @session_map == :half
        if get_subscription(request) != nil
          @ilog.debug("Moving the dialog to full on Subscription notify.") if @ilog.debug?
          SessionManager.find_session(request.call_id, request.to_tag, request.from_tag, true)
        end
      end
    end
    return true
  end
  
  def _update_dialog_state_on_response(response)
    if @behind_nat && response.via[:rport]
      contact_hdr = SipHeaders::Contact.new.assign(@our_contact)
      contact_hdr.uri.host = response.via.received.to_s
      contact_hdr.uri.port = response.via.rport.to_s
      @our_contact = contact_hdr.to_s
    end
    @dialog_routes.response_received(response)
    _on_common_sip(response)
    @imessage = @iresponse = response
    _check_for_pending_cancel
    @remote_tag = response.to_tag
    @remote_uri = response.to.to_s
  end
  
  # Reject the request if we have seen thsi CSeq before and there is no transaction 
  # found for this request which rules out a retransmission. 
  def _equal_cseq_check(request)
    if SipperConfigurator[:ProtocolCompliance] == 'strict' && 
      SipperUtil.cseq_number(request.cseq) == request.attributes[:_sipper_old_cseq]
      request.attributes[:_sipper_rejection_response] = rejection_response_with(500, @irequest)
      @ilog.debug("Rejected the request #{request.method} for out of (equal) CSeq") if @ilog.debug?
      false
    else
      true 
    end
  end
  
  # A UAS that receives a second INVITE before it sends the final response to 
  # a first INVITE with a lower CSeq sequence number on the same dialog MUST 
  # return a 500 (Server Internal Error) response to the second INVITE and 
  # MUST include a Retry-After header field with a randomly chosen value 
  # of between 0 and 10 seconds. 
  # 
  # A UAS that receives an INVITE on a dialog 
  # while an INVITE it had sent on that dialog is in progress MUST return a 
  # 491 (Request Pending) response to the received INVITE.
  def _check_pending_invite_txns_on_invite_in(request)
    @transactions.values.each do |txn|
      if txn.transaction_name == :Ict
        unless ["IctMap.Completed", "IctMap.Terminated"].include? txn.state     
          request.attributes[:_sipper_rejection_response] = rejection_response_with(491, request)
          return false
        end
      elsif txn.transaction_name == :Ist
        unless ["IstMap.Confirmed", "IstMap.Terminated", "IstMap.Finished"].include? txn.state
          r = rejection_response_with(500, request)
          r.retry_after = rand(10).to_s
          request.attributes[:_sipper_rejection_response] = r  
          return false
        end
      end    
    end
    return true
  end
  
  
  def _add_route_headers_if_present(msg, rrt)
    unless rrt[1].empty?
      msg.route = rrt[1] 
      msg.format_as_separate_headers_for_mv(:route)
    end
    msg.attributes[:_sipper_use_ruri_to_send] = rrt[2]
    msg
  end
  
  
  # populates the transport, rip and rp attributes in the session if they are not 
  # set. This can happen if an unbound session is created. 
  def _check_transport_and_destination(msg)
    if !(@transport && @rip && @rp) || (@dialog_routes.target_refreshed? && @detached_session)
      if (@controller && (cstp=@controller.specified_transport))
        msg.attributes[:_sipper_controller_specified_transport] =  cstp   
      end
      rv = Transport::TransportAndRouteResolver.ascertain_transport_and_destination(msg, self.class)
      @transport = rv[0]||@transport
      @rip = rv[1] || @rip
      @rp = rv[2] || @rp
    end
  end
  
  def _get_sq_lock
    @sq_lock
  end
  
  def _get_recorder
    @session_recorder
  end
  
  def _remove_recorder
    @session_recorder = nil
  end
  
  def create_subscription_from_request(request)
    # Creating subscription based on Subscribe/Refer request received.
    event = request.event.header_value if request["event".to_sym]

    unless event 
      if request.method == "REFER"
         event = "refer"
      else
         log_and_raise  "Invalid subscription", ArgumentError
      end
    end

    if event == "refer" && request.method != "REFER"
      log_and_raise  "Only Refer method can create refer subscription", ArgumentError
    end
    
    id_val = request.event['id'] if request["event".to_sym]
    unless id_val
      id_val = 0
    end
    
    key = sprintf("|%s|%d", event, id_val)
    subscription = @subscriptionMap[key]
    unless subscription 
      @ilog.debug("Creating new uas subscription object.") if @ilog.debug?
      subscription = SubscriptionData.new
      subscription.key = key
      subscription.timer = nil
      subscription.source = 'uas'
      subscription.event = event
      subscription.event_id = id_val
      subscription.state = 'active'
      subscription.method = request.method

      if request.method == "SUBSCRIBE"
        if request[:expires] and request.expires.header_value == '0'
          subscription.state = "terminated"
        end
      end
      @subscriptionMap[key] = subscription
    end
    
    return @subscriptionMap[key]
  end
  
  def create_subscription(event, id_val=0, method="SUBSCRIBE")
    # Creating new subscription.
    key = sprintf("|%s|%d", event, id_val)
    subscription = @subscriptionMap[key]
    unless subscription
      @ilog.debug("Creating new uac subscription object.") if @ilog.debug?
      subscription = SubscriptionData.new
      subscription.key = key
      subscription.timer = nil
      subscription.source = 'uac'
      subscription.event = event
      subscription.event_id = id_val
      subscription.state = 'active'
      subscription.method = method
      @subscriptionMap[key] = subscription
    end
    
    return subscription
  end
  
  def get_subscription(request)
    event = request.event.header_value if request["event".to_sym] 

    unless event 
      if request.method == "REFER"
         event = "refer"
      else
         log_and_raise  "Invalid subscription", ArgumentError
      end
    end
    
    event_id = request.event['id'] if request["event".to_sym]
    unless event_id 
      event_id = 0
    end
    
    key = sprintf("|%s|%d", event, event_id)
    subscription = @subscriptionMap[key]
    
    return subscription
  end
  
  def update_subscription(request)
    subscription = get_subscription(request)
    
    if request.method == "NOTIFY"
      subscription.state = request.subscription_state.header_value

      if request.subscription_state["expires"] != nil
         if request.subscription_state["expires"] == '0'
            subscription.state = "terminated"
         end
      end
    end
    
    if request.method == "SUBSCRIBE"
      if request.expires.header_value == '0'
        subscription.state = "terminated"
      end
    end
    
    return subscription
  end
  
  def remove_subscription(request)
    event = request.event.header_value if request["event".to_sym]

    unless event 
      if request.method == "REFER"
         event = "refer"
      else
         log_and_raise  "Invalid subscription", ArgumentError
      end
    end
    
    event_id = request.event.id if request["event".to_sym]
    unless event_id 
      event_id = 0
    end
    
    key = sprintf("|%s|%d", event, event_id)
    @subscriptionMap.delete(key)
  end
  
  def remove_subscription(subscription)
    @subscriptionMap.delete(subscription.key)
  end
  
  def add_subscription_to_request(request, subscription)
    @ilog.debug(subscription.to_s) if @ilog.debug?

    if subscription.event != "refer" || request.method != "REFER" || subscription.event_id != 0
       request.event = subscription.event
    end

    if subscription.event_id != 0
      request.event.id = subscription.event_id.to_s
    end
    
    if request.method == "NOTIFY"
      request['subscription-state'] = subscription.state
    end
  end
  
  def _schedule_timer_for_subscription(duration, subscription)
    @ilog.debug("Scheduling a subscription timer for #{duration}") if @ilog.debug?

    @timer_helper.cancel_timer(subscription.timer) if subscription.timer

    subscription.timer = @timer_helper.schedule_for(self, subscription, nil, :subscription, duration)
    @timer_list << subscription.timer
    subscription.timer
  end
  
  def start_subscription_expiry_timer(subscription, response)
    @ilog.debug('starting subscription expiry timer') if @ilog.debug?
    if subscription.state != "active" 
      @ilog.debug("Not scheduling timer as state is not active") if @ilog.debug?
      return
    end
    
    expires = response.expires.header_value
    if expires == nil 
      @ilog.debug("Not scheduling timer as expires is empty") if @ilog.debug?
      return
    end
    
    expiresDuration = expires.to_i * 1000
    
    @ilog.debug("Scheduling timer for subscription") if @ilog.debug?
    _schedule_timer_for_subscription(expiresDuration, subscription)
  end
  
  def start_subscription_refresh_timer(subscription, response)
    if subscription.state != "active" 
      @ilog.debug("Not starting refresh Timer as state is #{subscription.state}")if @ilog.debug?
      return
    end
    
    expires = response.expires.header_value
    if expires == nil 
      @ilog.debug("Not starting refresh Timer as expires is nil") if @ilog.debug?
      return
    end
    
    expiresDuration = (expires.to_i - 10) * 1000
    
    if (expiresDuration < 0)
      expiresDuration = expires.to_i * 500
    end
    
    @ilog.debug("Starting refresh Timer for #{expiresDuration}") if @ilog.debug?
    _schedule_timer_for_subscription(expiresDuration, subscription)
  end
  
  # Persists for REGISTRAR not REGISTRANT
  def _create_registration_object(message, persist=true)
    if message[:to] 
      aor = message.to.header_value
    else
      log_and_raise  "Invalid registration", ArgumentError
    end
    
    key = sprintf("%s", aor)
    reg_list = SIP::Locator[:RegistrationStore].get(key) if persist
    unless reg_list 
      @ilog.debug("Creating new registration object.") if @ilog.debug?
      reg_list =[]
      if message[:contact]
        message.contacts.each do|cn| 
          registration = Registration.add_registration_data(cn,message)
          reg_list.push(registration) if registration.expires.to_i != 0
        end  
      end
    else
      @ilog.debug("Updating registration object.") if @ilog.debug?
      message.contacts.each do|cn| 
        updated = Registration.update_registration_data(cn, reg_list, message)
        if not updated
          registration = Registration.add_registration_data(cn,message)
          reg_list.push(registration) if registration.expires.to_i != 0
        end  
      end    
    end
    
    if message[:expires]
      if message.expires.header_value == '0' and message.contact.header_value == '*'
        reg_list.clear
      end
    end
    SIP::Locator[:RegistrationStore].put(key, reg_list) if persist
    return reg_list
  end
  
  def _schedule_timer_for_registration(duration, registration)
    @ilog.debug("Scheduling a registration refresh timer for #{duration}") if @ilog.debug?
    task=@timer_helper.schedule_for(self, registration, nil, :registration, duration)
    @timer_list << task
    task
  end
  
  def start_registration_expiry_timer
    expires = '99999'
    @registrations.each do | reg_data |
      expires = reg_data.expires if expires.to_i > reg_data.expires.to_i
    end
    if expires.to_i == 0 
      @ilog.debug("Not starting registration refresh Timer as expires is 0") if @ilog.debug?
      return
    end
   
    expiresDuration = (expires.to_i - 10)*1000
    
    if (expiresDuration < 0)
      expiresDuration = expires.to_i * 500
    end
    @ilog.debug("Starting registration expiry Timer for #{expiresDuration}") if @ilog.debug?
    _schedule_timer_for_registration(expiresDuration, @registrations)
  end
  
  def offer_answer=(val)
    @offer_answer.close if @offer_answer && val.nil?
    @offer_answer = val
  end
  
  def create_replaces_header
    replaces = call_id.to_s + ";from-tag=" + local_tag.to_s + ";to-tag=" + remote_tag.to_s
    if irequest.method == "INVITE"
      replaces = replaces.to_s + ";early-only"
    else
      replaces = replaces.to_s + ";confirmed"
   end  
    return replaces
  end
  
  def find_session_from_replaces
    callid = irequest.replaces.header_value
    localtag = irequest.replaces["to-tag"]
    remotetag = irequest.replaces["from-tag"]
    session = SessionManager.find_session(callid, localtag, remotetag)
    return session
  end 
  
  # realm is used by UAS setting it in the response challenge
  def set_realm(val)
    @realm = val  
  end
  
  
  def create_reginfo_doc(aor, ver, contacts=nil)
    XmlDoc::RegInfoDoc.create(aor,ver,contacts)
  end  
  
  def create_pidf_doc(entity,pidftuple=nil,presence_note=nil)
    XmlDoc::PidfDoc.create(entity,pidftuple,presence_note)
  end
  
  protected :_get_sq_lock, :_get_recorder, :_remove_recorder
  private :_on_request, :_on_response,  :_on_common_sip, :_do_record_sip, :_check_cancel_state, 
  :_check_for_pending_cancel, :_fixed_local_tag, :_send_common, 
  :_schedule_timer_for_session, :_increment_local_cseq, :_update_and_check_dialog_state_on_request,
  :_add_route_headers_if_present, :_check_transport_and_destination, :_create_registration_object
  
end
