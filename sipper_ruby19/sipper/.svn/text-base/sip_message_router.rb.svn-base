require 'transport/udp_transport'
require 'sip_logger'
require 'util/sipper_util'
require 'message'
require 'request'
require 'response'
require 'session'
require 'udp_session'
require 'tcp_session'
require 'util/timer/timer_task'
require 'stray_message_manager'
require 'sipper_http/sipper_http_response'
require 'sipper_http/sipper_http_servlet_request_wrapper'

class SipMessageRouter

  include SipLogger
  include SipperUtil
  
  attr_reader :tg, :running
  
  def initialize(queue, num_threads=5)
    @ilog = logger
    @q = queue
    @num_threads = num_threads
    @tg = ThreadGroup.new
    @running = false  
    @run = false
    # todo running and run is not thread safe 
    log_and_raise "Message Queue is not set", ArgumentError unless @q
  end
  
  
  def start
    @run = true
    1.upto(@num_threads) do |i|
      @tg.add(
        Thread.new do
          Thread.current[:name] = "WorkerThread-"+i.to_s
          while @run
            msg = @q.pop
            #@ilog.debug("Message #{msg} picked up from queue") if @ilog.debug?
            @ilog.info("Message picked from queue, now parsing") if @ilog.info?
            begin
               r = Message.parse(msg)
            rescue ArgumentError
                @ilog.warn("DONT KNOW WHAT YOU SENT") if @ilog.warn?
                next
            end

            2.times do  # one optional retry
              case r
              when Request
                @ilog.debug("REQUEST RECEIVED #{r}") if @ilog.debug?
                logsip("I", r.rcvd_from_info[3], r.rcvd_from_info[1], r.rcvd_at_info[0], r.rcvd_at_info[1], r.rcvd_at_info[2], r)
                if r.to_tag && !r.attributes[:_sipper_initial]
                  # call_id, local, remote
                  s = SessionManager.find_session(r.call_id, r.to_tag, r.from_tag)  
                  if s
                    s.on_message r
                    break
                  else
                    if hndlr = SIP::StrayMessageManager.stray_message_handler
                      @ilog.debug("Found a stray message handler for the request, invoking it") if @ilog.debug?
                      ret = hndlr.handle(r)
                      case ret[0]
                      when SIP::StrayMessageHandler::SMH_DROP
                        @ilog.warn("A stray request #{r.method} being dropped by SMH") if @ilog.warn?
                        break
                      when SIP::StrayMessageHandler::SMH_HANDLED
                        @ilog.debug("A stray request #{r.method} handled by SMH") if @ilog.debug?
                        break
                      when SIP::StrayMessageHandler::SMH_RETRY
                        @ilog.debug("A stray request #{r.method} received, SMH retries") if @ilog.debug?
                        r = ret[1] if ret[1]
                        if r.attributes[:_sipper_retried]
                          @ilog.warn("Already retried request now dropping") if @ilog.warn?
                          break
                        else
                          r.attributes[:_sipper_retried] = true
                          next
                        end
                      when SIP::StrayMessageHandler::SMH_TREAT_INITIAL
                        @ilog.debug("A stray request #{r.method} received, SMH treating as initial") if @ilog.debug?
                        r = ret[1] if ret[1]
                        if r.attributes[:_sipper_initial]
                          @ilog.warn("Already retried request now dropping") if @ilog.warn?
                          break
                        else
                          r.attributes[:_sipper_initial] = true
                          next
                        end
                      else
                        @ilog.warn("A stray request #{r.method} SMH response not understood, dropping") if @ilog.warn?
                        break
                      end
                    else
                      @ilog.warn("A stray request #{r.method} received, dropping as no handler") if @ilog.warn?
                      break
                    end  
                  end
                else
                  # call_id, local, remote
                  s = SessionManager.find_session(r.call_id, r.to_tag, r.from_tag)
                  if s
                    @ilog.debug("Matched session #{s}") if @ilog.debug?
                    s.on_message r
                    break
                  else  # create a new session
                    @ilog.debug("No matching session found") if @ilog.debug?
                    ctrs = SIP::Locator[:Cs].get_controllers(r)
                    @ilog.debug("Initial request, total controllers returned are #{ctrs.size}") if @ilog.debug?
                    ctrs.each do |c| 
                      if c.interested?(r)
                        @ilog.debug("Controller #{c.name} is interested in #{r.method}") if @ilog.debug?
                        #["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]
                        # todo tcp support here
                        if stp = c.specified_transport
                          @ilog.debug("Controller #{c.name} specified #{stp} transport") if @ilog.debug?
                          unless (stp[0] == r.rcvd_at_info[0] &&  
                                  stp[1] == r.rcvd_at_info[1])
                            next        
                          end        
                        end
    
                        if(r.rcvd_at_info[2] == "UDP")  
                          s = c.create_udp_session(r.rcvd_from_info[3], r.rcvd_from_info[1])
                        elsif (r.rcvd_at_info[2] == "TCP")
                          s = c.create_tcp_session(r.rcvd_from_info[3], r.rcvd_from_info[1], nil, r.rcvd_at_info[3])
                        else
                          @ilog.error("Unknown type of transport #{r.rcvd_at_info[2]} cannot create session") if @ilog.error?
                        end
                        s.pre_set_dialog_id(r)  # to facilitate addition in session manager 
                        SessionManager.add_session(s, false)
                        s.on_message(r)
                        break
                      end
                    end  # controller loop
                    # if no controller on initial request then respond with 502
                    unless s
                      if hndlr = SIP::StrayMessageManager.stray_message_handler
                        @ilog.debug("Found a stray message handler for the init request, invoking it") if @ilog.debug?
                        ret = hndlr.handle(r) 
                        case ret[0]
                        when SIP::StrayMessageHandler::SMH_DROP
                          @ilog.warn("A stray init request #{r.method} being dropped by SMH") if @ilog.warn?
                          break
                        when SIP::StrayMessageHandler::SMH_HANDLED
                          @ilog.debug("A stray init request #{r.method} handled by SMH") if @ilog.debug?
                          break
                        when SIP::StrayMessageHandler::SMH_RETRY
                          @ilog.debug("A stray init request #{r.method} received, SMH retries") if @ilog.debug?
                          r = ret[1] if ret[1]
                          if r.attributes[:_sipper_retried]
                            @ilog.warn("Already retried init request now dropping") if @ilog.warn?
                            break
                          else
                            r.attributes[:_sipper_retried] = true
                            next
                          end
                        else
                          @ilog.warn("A stray init request #{r.method} SMH response not understood, dropping") if @ilog.warn?
                          break
                        end
                      else
                        # todo either send a 502 or cleanup the log
                        @ilog.warn("A stray init request #{r.method} received, sending 502") if @ilog.warn?
                        break
                      end
                    else
                      break
                    end
                  end  # if session found
                end  # r.to-tag
  
              when Response
                @ilog.debug("RESPONSE RECEIVED #{r}") if @ilog.debug?
                logsip("I", r.rcvd_from_info[3], r.rcvd_from_info[1],  r.rcvd_at_info[0], r.rcvd_at_info[1], r.rcvd_at_info[2], r)
                # call_id, local, remote
                s = SessionManager.find_session(r.call_id, r.from_tag, r.to_tag, (SipperUtil::SUCC_RANGE.include?r.code))
                if s
                  @ilog.debug("Session found, sending response to session") if @ilog.debug?
                  s.on_message r
                  break
                else
                  if hndlr = SIP::StrayMessageManager.stray_message_handler
                    @ilog.debug("Found a stray message handler for the response, invoking it") if @ilog.debug?
                    ret = hndlr.handle(r)
                    case ret[0]
                    when SIP::StrayMessageHandler::SMH_DROP
                      @ilog.warn("A stray response #{r.code} being dropped by SMH") if @ilog.warn?
                      break
                    when SIP::StrayMessageHandler::SMH_HANDLED
                      @ilog.debug("A stray response #{r.code} handled by SMH") if @ilog.debug?
                      break
                    when SIP::StrayMessageHandler::SMH_RETRY
                      @ilog.debug("A stray response #{r.code} received, SMH retries") if @ilog.debug?
                      r = ret[1] if ret[1]
                      if r.attributes[:_sipper_retried]
                        @ilog.warn("Already retried response now dropping") if @ilog.warn?
                        break
                      else
                        r.attributes[:_sipper_retried] = true
                        next
                      end
                    else
                      @ilog.warn("A stray response #{r.code} SMH response not understood, dropping") if @ilog.warn?
                      break
                    end
                  else
                    @ilog.warn("A stray response #{r.code} received, dropping") if @ilog.warn?
                    break
                  end
                end
                
              when SIP::TimerTask
                @ilog.debug("TIMER RECEIVED #{r}") if @ilog.debug?
                r.invoke
                break
              when Media::SipperMediaEvent
                @ilog.debug("Media Response/Event received") if @ilog.debug?
                r.session.on_message r
                break
              when SipperHttp::SipperHttpResponse
                @ilog.debug("Sipper HTTP response received") if @ilog.debug?
                r.dispatch
                break
              else
                @ilog.warn("DONT KNOW WHAT YOU SENT") if @ilog.warn?
                break
              end
            end
          end
        end
      )
    end
    @running = true
  end
  
  def handle_http_req(req, res)
    ctrs = SIP::Locator[:Cs].get_controllers
    @ilog.debug("Initial HTTP request, total controllers returned are #{ctrs.size}") if @ilog.debug?
    s = nil
    ctrs.each do |c| 
      if c.interested_http?(req)   
        @ilog.debug("Controller #{c.name} is interested in #{req.request_method}") if @ilog.debug?
        s = c.create_session                                      
        SessionManager.add_session(s, false)
      end
    end
    if s
      return s
    else   
      return nil
    end
  end
  
  
  def stop
    @run = false
    @running = false
    @tg.list.each { |t| t.kill }
  end
  
end
