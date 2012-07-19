require 'transport/base_transport'

class MyInTransportHandler2 < Transport::TransportIngressFilter
  def do_filter(msg)
    m = msg.gsub(/zz/, "aa") unless msg =~ /200 OK/ 
    m ? m : msg
  end  
end

class MyOutTransportHandler1 < Transport::TransportOutgressFilter
  def do_filter(msg)
    m = msg.gsub(/xx/, "yy") unless msg =~ /200 OK/ 
    m ? m : msg
  end
end


=begin
  UAC (only on requests)                                          UAS
  >--Test-Header(xx->yy)(yy->zz) -->-------(zz->aa)(aa->bb)-------->
=end