module SIP
  module Transport
    
    module ReliableTransport
      def reliable?
        true
      end
    end
    
    module UnreliableTransport
      def reliable?
        false
      end
    end
    
  end
end
  
  
