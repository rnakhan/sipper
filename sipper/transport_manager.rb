require 'transport/udp_transport'

class TransportManager

  attr_reader :transports
    
  def initialize
    @transports = []
  end
  
  def add_transport tp
    @transports << tp
  end  
  
  #["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]
  def get_transport_for(transport_info)
    @transports[0]   #todo have the MH algo here
  end
  
  # todo find a way to return a different
  # this return transport suitable for sending to ip / port
  def get_udp_transport_for(ip, port)
    @transports.each {|t| return t if t.tid  == "UDP"}
  end
  
  # This returns a transport that matches the ip and port as given
  def get_udp_transport_with(ip, port)
    @transports.each do |tr|
      return tr if (tr.tid  == "UDP" && tr.ip == ip && tr.port == port)  
    end
  end
  
  def get_tcp_transport_for(ip, port)
    @transports.each {|t| return t if t.tid  == "TCP"}
  end
  
  # This returns a transport that matches the ip and port as given
  def get_tcp_transport_with(ip, port)
    @transports.each do |tr|
      return tr if (tr.tid  == "TCP" && tr.ip == ip && tr.port == port)  
    end
  end
  
end
