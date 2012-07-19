require 'transport/base_transport'

class MyInTransportHandler < Transport::TransportIngressFilter
  def do_filter(msg)
    m = msg.gsub(/MESSAGE/, "INFO") if msg =~ /200 OK/ 
    m ? m : msg
  end  
end

class MyOutTransportHandler < Transport::TransportOutgressFilter
  def do_filter(msg)
    m = msg.gsub(/INFO/, "MESSAGE") 
    m ? m : msg
  end
end


=begin
  UAC                                  UAS
  >--INFO--(conv MESSAGE) -->----------MESSAGE
  <--200/INFO--(conv INFO)--<-------200/MESSAGE  
=end