
module SIP
 
  class StrayMessageHandler
    
    SMH_DROP          = 8000
    SMH_HANDLED       = 8001
    SMH_RETRY         = 8002
    SMH_TREAT_INITIAL = 8003
    
    # Filter on anonymous Module because if the stray handler is defined inline then 
    # we load the string twice, once in an anonymous module and once in top 
    # level object. We do not want to register the stray handler twice. 
    def self.inherited(child)
      @stray_message_handler = child.new unless child.to_s =~ /^#<Module/
    end
    
    # default handler
    def handle(msg)
      [SIP::StrayMessageHandler::SMH_DROP, nil]
    end
   
    class << self; attr_accessor :stray_message_handler end
  end
  
  
  class StrayMessageManager
  
    def self.stray_message_handler
        return StrayMessageHandler.stray_message_handler
    end
    
    def self.clear_handler
      StrayMessageHandler.stray_message_handler = nil
    end
    
  end
  
end

