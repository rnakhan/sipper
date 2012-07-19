require 'thread'
require 'monitor'
require 'util/message_fill'
require 'sip_logger'
require 'ruby_ext/object'
require 'transport/rel_unrel'
require 'transport/base_transport'
require 'message'


module Transport
  class UdpTransport < BaseTransport
  
    include SipLogger
    include SIP::Transport::UnreliableTransport  # returns false for reliable? check.
    
    private_class_method :new
    
    MAX_RECV_BUFFER = 65500
      
    @@instance = {}
    @@class_lock = Monitor.new
    
    # comment : need to synchronize on queue and running paramaters
    
    
    def initialize(ip, port, external_q)
      @ilog = logger
      @tid = "UDP"
      if external_q
        @queue = external_q
      else 
        @queue = Queue.new 
      end
      @ip = ip
      @port = port
      @running = false
      @running_lock = Monitor.new 
      @ilog.info("Created a new udptransport with #{@ip} and #{@port}") if @ilog.info?
    end
    
    
    def to_s
      @str = "udptransport ip=#{@ip}, port=#{@port}" unless @str
      @str
    end
    
    def UdpTransport.instance(i, p, q=nil)
      @@class_lock.synchronize do 
        k = i.to_s + ":" + p.to_s
        @@instance[k] = new(i, p, q) unless @@instance[k]
        @@instance[k]  
      end
    end
    
    
    def start_transport
      @ilog.info("Starting the transport #{self}") if @ilog.info?
      #@running_lock.synchronize do
        fail "Already running" if @running
        @running = true
      #end
      t = Thread.new do
        Thread.current[:name] = "UDPThread-"+@ip.to_s+"-"+@port.to_s
        UDPSocket.do_not_reverse_lookup = true
        @sock = UDPSocket.new
        @sock.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)

        @sock.bind(@ip, @port)
        @ilog.debug "binded ..#{@port}" if @ilog.debug?
        begin 
          loop do
            #puts "starting the select loop.."
            IO.select([@sock])
            mesg = @sock.recvfrom_nonblock(MAX_RECV_BUFFER)
            in_filter = nil
            BaseTransport.in_filters.each do |in_filter|
              @ilog.debug("Ingress filter applied is #{in_filter.class.name}") if @ilog.debug?
              mesg[0] = in_filter.do_filter(mesg[0])
              break unless mesg[0]
            end
            #["msg", ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]]
            if @ilog.debug?
              @ilog.debug("Message received is - ")
              x= nil
              i = nil
              mesg.each_with_index {|x,i| @ilog.debug(" > mesg[#{i}]=#{x}")}    
            end
            if mesg[0]
              mesg << [@ip, @port, @tid]
              @queue << mesg
              #@ilog.info("Message recvd on transport and enqueued on #{@queue}") if @ilog.info?
            else
              @ilog.info("Message recvd on transport does not have the payload or is consumed by a filter, not enquing") if @ilog.info?
            end
            break if mesg[0] =~ /poison dart/
          end  # loop
          rescue  => detail
            @ilog.debug detail.backtrace.join("\n") if @ilog.debug?
            @ilog.error("Exception #{detail} occured for #{self}") if @ilog.error?
            @sock.close
            break
        end  # exception
      end 
      @t_thread = t
      return t
    end 
    
    def stop_transport
      @ilog.info("Stopping transport #{self}") if @ilog.info?
      #@running_lock.synchronize do
        fail "Already stopped" unless @running
        @running = false
      #end
      @sock.close
      @t_thread.kill
      k = @ip.to_s + ":" + @port.to_s
      @@instance.delete(k)
    end
    
   
    def send(mesg, flags, *ipport)
      if mesg.class <= ::Message 
        smesg = mesg.to_s
      else
        smesg = mesg
      end 
      @ilog.info("Sending message #{smesg} using #{self} to ip=#{ipport[0]} and port=#{ipport[1]}") if @ilog.info?
      if smesg =~ /_PH_/
        @ilog.debug("Now filling in message of class #{smesg.class}") if @ilog.debug?
        SipperUtil::MessageFill.sub(smesg, :trans=>@tid, :lip=>@ip, :lp=>@port.to_s) 
      else
        @ilog.debug("Nothing to fill in message of class #{smesg.class}") if @ilog.debug?
      end
      out_filter = nil  
      BaseTransport.out_filters.each do |out_filter|
        @ilog.debug("Outgress filter applied is #{out_filter.class.name}") if @ilog.debug?
        smesg = out_filter.do_filter(smesg)
        break unless smesg
      end
      logsip("O", ipport[0], ipport[1], @ip, @port, @tid, smesg)
      if smesg
        @sock.send(smesg, flags, ipport[0], ipport[1])
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
