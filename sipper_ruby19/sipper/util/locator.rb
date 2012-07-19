# Holds references for - 
# :Tm => Transport Manager
# :Cs => Controller Selector
# :Sipper => Main class
# :Tlocks => A hash of locks structure for tests signaling. If not found locally then this is 
#            additionally searched in the remote TestServer if present in the configuration. 
#            This is for the cases where the UAS is running on a separate node
# :Sth   => SIP Timer helper, which is the central class to schedule the SIP timers including
#           app level timers.
# 

require 'sipper_configurator'

module SIP
 
  class Locator
    
     @@services_hash = {}
     @@ro = nil
     
     def Locator.[](k)
       @@services_hash[k] 
     end
    
     def Locator.[]=(k,v)
       @@services_hash[k] = v  
     end
     
  end
  
end