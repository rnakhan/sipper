require 'transport/base_transport'

class MyInTransportHandler1 < Transport::TransportIngressFilter
  def do_filter(msg)
    m = msg.gsub(/aa/, "bb") unless msg =~ /200 OK/ 
    m ? m : msg
  end  
end

class MyOutTransportHandler2 < Transport::TransportOutgressFilter
  def do_filter(msg)
    m = msg.gsub(/yy/, "zz") unless msg =~ /200 OK/ 
    m ? m : msg
  end
end


=begin
  UAC (only on requests)                                          UAS
  >--Test-Header(xx->yy)(yy->zz) -->-------(zz->aa)(aa->bb)-------->
=end
