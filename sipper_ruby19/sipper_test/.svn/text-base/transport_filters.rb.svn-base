class InTransportHandler2 < Transport::TransportIngressFilter
  def do_filter(msg)
    m = msg.sub!(/_b_/, "2")
    m ? m : msg
  end  
end
class InTransportHandler1 < Transport::TransportIngressFilter
  def do_filter(msg)
    m = msg.sub!(/_a_/, "1")
    m ? m : msg
  end  
end


class OutTransportHandler1 < Transport::TransportOutgressFilter
  def do_filter(msg)
    m = msg.sub!(/_a_/, "1")
    m ? m : msg
  end
end
class OutTransportHandler2 < Transport::TransportOutgressFilter
  def do_filter(msg)
    m = msg.sub!(/_b_/, "2")
    m ? m : msg
  end
end