require 'singleton'


module Media
  class SipperMediaManager
  
    include SipLogger

    include Singleton

    def initialize()
       @ilog = logger
       @cal = Monitor.new # command send lock

       @csl = Monitor.new # command status lock
       @csl_cmd = @csl.new_cond

       @media_clients = {}
       @media_clients.extend(MonitorMixin)

       start
    end
    
    def set_queue(q)
      @q = q
    end
    
    def enqueue_event(event)
      @q << event
    end
    
    def start
      return false unless SipperConfigurator[:SipperMedia]
      sipperMediaIp = SipperConfigurator[:SipperMediaIP]
      unless sipperMediaIp
         sipperMediaIp = SipperConfigurator[:LocalSipperIP]
      end

      @t =  TCPSocket.new(sipperMediaIp, SIP::Locator[:Smd].controller_port) 
      
      Thread.new do
        while true do
          ready = select([@t], nil, nil, nil)        
          next if not ready        
          ready[0].each do |s|
            next if s.eof         
            msg_len = s.readpartial(4).unpack("N")[0]
            r = s.readpartial(msg_len)

            @ilog.debug("Message received on socket Len[#{msg_len}] Msg[#{r}]") if @ilog.debug?

            if r.include?'TYPE=Result;'
              cm = rs = md = rn = ri = rp = nil
              otherparams={}
              r.split(';').each do |x|
                y = x.split('=')
                case y[0]
                when 'COMMAND'
                  cm = y[1]
                when 'MEDIAID'
                  md = y[1]
                when 'RESULT'
                  rs = y[1]
                when 'RECVIP'
                  ri = y[1]
                when 'RECVPORT'
                  rp = y[1]
                when 'REASON'
                  rn = y[1]
                else
                  otherparams[y[0]] = y[1]
                end  
              end
              
              reply = Media::SmReply.new(nil, cm, rs, md, rn, ri, rp, otherparams)
              _process_reply(reply)

            elsif r.include?'TYPE=EVENT;' 
              md = cd = ev = dt = nil
              r.split(';').each do |x|
                y = x.split('=')
                case y[0]
                when 'CODEC'
                  cd = y[1]
                when 'MEDIAID'
                  md = y[1]
                when 'EVENT'
                  ev = y[1]
                when 'DTMF'
                  dt = y[1]
                end  
              end

              event_client = nil

              @media_clients.synchronize do
                 event_client = @media_clients[md] 
              end

              if event_client == nil
                 @ilog.debug("Stray event received.#{r}") if @ilog.debug?
              else
                 evt = Media::SmEvent.new(event_client.session, md, cd, ev, dt)
                 enqueue_event(evt)
              end
            end
          end
        end #listener loop       
      end # thread
      return true
    end

    def _process_reply(reply)
        @csl.synchronize do
           @command_result = reply
           @csl_cmd.signal
        end
    end

    def send_command(mediaClient, commandStr)
      @cal.synchronize do
        @csl.synchronize do
           @ilog.debug("Sending media Len[#{commandStr.length}] Command[#{commandStr}]") if @ilog.debug?
           @t << [commandStr.length].pack("N") << commandStr

           5.times do
              if @csl_cmd.wait(10)
                 returnVal = @command_result
                 @command_result = nil
                 returnVal.session = mediaClient.session

                 @media_clients.synchronize do
                    if returnVal.cmd == "CREATE MEDIA" && returnVal.result == "Success"
                       @media_clients[returnVal.media_id] = mediaClient
                    end

                    if returnVal.cmd == "DESTROY MEDIA" && returnVal.result == "Success"
                       @media_clients.delete(returnVal.media_id)
                    end
                 end

                 return returnVal
              end
           end
           @ilog.debug("Unable to get result after 5 retries 50Sec. Command: #{commandStr}") if @ilog.debug?
           Process.exit(1)
        end
      end
    end
  end
end
