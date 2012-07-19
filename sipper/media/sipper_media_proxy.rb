require 'sipper_configurator'
require 'util/sipper_util'


module Media
  class SipperMediaProxy
    
    include SipLogger
    attr_reader :controller_port
    
    def initialize(controller_port=nil)
      @ilog = logger
      @controller_port = controller_port || SipperConfigurator[:SipperMediaDefaultControlPort]

      return if SipperConfigurator[:SipperMediaProcessReuse] && self.ping

      if self.ping
        loop do
          self.shutdown  
          sleep 2
          break unless self.ping
        end
      end
      Thread.new do
        
        x = system(File.join(File.dirname(__FILE__), "..", "..", "bin", "SipperMedia") +" -p " + "#{@controller_port.to_s}")
      
      end
      loop do
        sleep 2
        break if self.ping
      end
    end
    
    def ping
      begin
        sipperMediaIp = SipperConfigurator[:SipperMediaIP]
        unless sipperMediaIp
           sipperMediaIp = SipperConfigurator[:LocalSipperIP]
        end

        t =  TCPSocket.new(sipperMediaIp, @controller_port)
      rescue SystemCallError
        return false
      end
      t.close
      return true
    end
    
    def shutdown
      begin
        sipperMediaIp = SipperConfigurator[:SipperMediaIP]
        unless sipperMediaIp
           sipperMediaIp = SipperConfigurator[:LocalSipperIP]
        end

        t =  TCPSocket.new(sipperMediaIp, @controller_port)
        #t.setsockopt(Socket::IPPROTO_TCP, Socket::NONBLOCK, true)
        t.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, true)
      rescue SystemCallError
        return
      end     
      command = "COMMAND=SHUTDOWN"
      t << [command.length].pack("N") << command
      len = t.readpartial(4).unpack("N")[0]
      reply = t.readpartial(len)
      @ilog.debug("Received media shutdown Reply #{reply}") if @ilog.debug?
      t.close
    end
        
    
  end
end
