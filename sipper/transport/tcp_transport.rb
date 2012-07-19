
require 'thread'
require 'monitor'
require 'util/message_fill'
require 'sip_logger'
require 'ruby_ext/object'
require 'transport/rel_unrel'
require 'transport/base_transport'
require 'message'
require 'timeout'
require 'util/sipper_util'

module Transport
  class TcpTransport < BaseTransport
    
    include SipLogger
    include SipperUtil
    include SIP::Transport::ReliableTransport 
    
    private_class_method :new
    
    attr_accessor :queue
    
    MAX_RECV_BUFFER = 1024*4
    
    CR   = "\x0d"
    LF   = "\x0a"
    CRLF = "\x0d\x0a"
    @@instance = {}
    @@class_lock = Monitor.new
    
    # comment : need to synchronize on queue and running paramaters
    
    
    def initialize(ip, port, external_q)
      @ilog = logger
      @tid = "TCP"
      if external_q
        @queue = external_q
      else 
        @queue = Queue.new 
      end
      @ip = ip
      @port = port
      @running = false
      @running_lock = Monitor.new 
      @ilog.info("Created a new tcp transport with #{@ip} and #{@port}") if @ilog.info?
    end
    
    
    def to_s
      @str = "tcptransport ip=#{@ip}, port=#{@port}" unless @str
      @str
    end
    
    def TcpTransport.instance(i, p, q=nil)
      @@class_lock.synchronize do 
        k = i.to_s + ":" + p.to_s
        @@instance[k] = new(i, p, q) unless @@instance[k]
        @@instance[k]  
      end
    end
    
    
    def start_transport
      @ilog.info("Starting the tcp transport #{self}") if @ilog.info?
      #@running_lock.synchronize do
      fail "Already running" if @running
      @running = true
      #end
      t = Thread.new do
        Thread.current[:name] = "TCPThread-"+@ip.to_s+"-"+@port.to_s
        TCPSocket.do_not_reverse_lookup = true
        serv = TCPServer.new(@ip.to_s, @port)
        begin 
          loop do       
            begin
              #sock = serv.accept_nonblock
              sock = serv.accept
            rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EINTR, Errno::EWOULDBLOCK
              IO.select([sock]) if sock
              retry
            end
            start_sock_thread(sock)
          end  # loop
        rescue  => detail
          @ilog.debug detail.backtrace.join("\n") if @ilog.debug?
          @ilog.error("Exception #{detail} occured for #{self}")
          break
        end  # exception
      end 
      @t_thread = t
      return t
    end 
    
    def start_sock_thread(sock)
      Thread.start{
        begin
          begin
            addr = sock.peeraddr
            @ilog.debug "accept: #{addr[3]}:#{addr[1]}" if @ilog.debug?
          rescue SocketError
            @ilog.debug "accept: <address unknown>" if @ilog.debug?
            raise
          end
          run(sock)
        rescue Errno::ENOTCONN
          @ilog.debug "Errno::ENOTCONN raised" if @ilog.debug?
        rescue Exception => ex
          @ilog.error "Exception2 raised "+ex
          @ilog.debug ex.backtrace.join("\n")  if @ilog.debug?
        end
      }
    end
    
    def run(sock)
      while true 
        begin
          timeout = SipperConfigurator[:TcpRequestTimeout]||500
          while timeout > 0
            break if IO.select([sock], nil, nil, 0.5)
            timeout = 0 unless @running
            timeout -= 0.5
          end
          if timeout <= 0
            sock.close
            return
          end
          raw_mesg_arr = Array.new
          while line = self.rd_line(sock)
            if /\A(#{CRLF}|#{LF})\z/om =~ line
              break if raw_mesg_arr.length > 0  # ignore leading CRLF
            end
            raw_mesg_arr << line.strip
            if line =~ /content-length/i
              l = line.strip
              st = l =~ /\d/
              en = l =~ /\d$/ if st
              cl = line[st..en] if st && en
            end  
          end
          return if raw_mesg_arr.length == 0
          log_and_raise "No Content-Length." unless cl
          body = ""
          block = Proc.new{|chunk| body << chunk << "\n"}
          
          remaining_size = cl.to_i
          cl = nil
          @ilog.debug("Reading TCP message content, length is #{remaining_size}") if @ilog.debug?
          while remaining_size > 0 
            sz = MAX_RECV_BUFFER < remaining_size ? MAX_RECV_BUFFER : remaining_size
            break unless buf = read_data(sock, sz)
            remaining_size -= buf.size
            block.call(buf)
          end
          if remaining_size > 0 && sock.eof?
            log_and_raise "invalid body size."
          end
          msg = raw_mesg_arr.join("\n")
          msg << CRLF 
          msg << CRLF
          msg << body
          # [msg, ["AF_INET", 49361, "ashirs-PC", "127.0.0.1"]]
          mesg = [msg, sock.peeraddr]  
          BaseTransport.in_filters.each do |in_filter|
            @ilog.debug("Ingress filter applied is #{in_filter.class.name}") if @ilog.debug?
            mesg[0] = in_filter.do_filter(mesg[0])
            break unless mesg[0]
          end
          #["msg", ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
          if @ilog.debug?
            @ilog.debug("Message received is - ") if @ilog.debug?
            mesg.each_with_index {|x,i| @ilog.debug(" > mesg[#{i}]=#{x}") if @ilog.debug? }    
          end
          if mesg[0]
            mesg << [@ip, @port, @tid, sock]
            #["msg", ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"], [our_ip, our_port, TCP, socket]]
            @queue << mesg
          else
            @ilog.info("Message recvd on transport does not have the payload or is consumed by a filter, not enquing") if @ilog.info?
          end     
        end
      end
    end
    
    
    
    def _read_data(io, method, arg)
      begin
        timeout(SipperConfigurator[:TcpRequestTimeout]){
          return io.__send__(method, arg)
        }
      rescue Errno::ECONNRESET
        return nil
      rescue TimeoutError
        log_and_raise "TCP request timeout"
      end
    end
    
    def rd_line(io)
      return _read_data(io, :gets, LF)
    end
    
    def read_data(io, size)
      _read_data(io, :read, size)
    end
    
    def stop_transport
      @ilog.info("Stopping transport #{self}") if @ilog.info?
      #@running_lock.synchronize do
      fail "Already stopped" unless @running
      @running = false
      #end
      @t_thread.kill
      k = @ip.to_s + ":" + @port.to_s
      @@instance[k] = nil
    end
    
    
    def send(mesg, flags, rip, rp, sock)
      if mesg.class <= ::Message 
        smesg = mesg.to_s
      else
        smesg = mesg
      end 
      @ilog.info("Sending message #{smesg} using #{self} to ip=#{rip} and port=#{rp}") if @ilog.info?
      if smesg =~ /_PH_/
        @ilog.debug("Now filling in message of class #{smesg.class}") if @ilog.debug?
        SipperUtil::MessageFill.sub(smesg, :trans=>@tid, :lip=>@ip, :lp=>@port.to_s) 
      else
        @ilog.debug("Nothing to fill in message of class #{smesg.class}") if @ilog.debug?
      end
      
      BaseTransport.out_filters.each do |out_filter|
        @ilog.debug("Outgress filter applied is #{out_filter.class.name}") if @ilog.debug?
        smesg = out_filter.do_filter(smesg)
        break unless smesg
      end
      logsip("O", rip, rp, @ip, @port, @tid, smesg)
      if smesg  
        if sock.nil? || sock.closed?
          sock = TCPSocket.new(rip, rp)
          start_sock_thread(sock) # start listening as well
        end
        sock.send(smesg, flags)
      else
        @ilog.info("Not sending the message as it has probably been nilled out by a filter") if @ilog.info?
      end
      smesg  # returns for recorder etc.
    end
    
    def get_next_message
      @queue.pop
    end
    
    
    def running
      @running_lock.synchronize do
        return @running
      end
    end
    
  end
end

=begin 
t = Transport::TcpTransport.instance("127.0.0.1", 2224)
th = t.start_transport
th.join(10)
p t.queue
puts t.queue.length

if t.queue.length > 0
  m = t.queue.pop
  if m
    puts m[0]
    puts "----------------"
    puts m[1]
    puts "----------------"
    puts m[2]
    puts "----------------"
  end
end
=end
