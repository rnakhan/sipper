require 'sipper_configurator'
require 'socket'

Socket.do_not_reverse_lookup = true

module Transport

  # Pre filter : for incoming messages 
  class TransportIngressFilter
    
    # Filter on anonymous Module because if the transport handler is defined inline then 
    # we load the string twice, once in an anonymous module and once in top 
    # level object. We do not want to register the transport handler twice. 
    def self.inherited(child)
      TransportIngressFilter.registered_filters << child.new unless child.to_s =~ /^#<Module/
    end
    
    # default handler
    def do_filter(msg)
      msg
    end
    
    @registered_filters = []
    class << self; attr_reader :registered_filters end
  end
  
  # Post filter : for outgoing messages
  class TransportOutgressFilter
  
    def self.inherited(child)
      TransportOutgressFilter.registered_filters << child.new unless child.to_s =~ /^#<Module/
    end
    
    # default handler
    def do_filter(msg)
      msg
    end
    
    @registered_filters = []
    class << self; attr_reader :registered_filters end
  end
  
  
  class BaseTransport
  
    attr_reader :running, :ip, :port, :tid
    
    @@out_oa = nil
    @@in_oa = nil
    
    def self.in_order=(order_arr)
      @@in_oa = order_arr   
    end
    
    def self.out_order=(order_arr)
      @@out_oa = order_arr
    end
    
    def self.in_filters
      if @@in_oa
        return TransportIngressFilter.registered_filters.sort do |x,y|
            (@@in_oa.index(x.class.name)?@@in_oa.index(x.class.name):@@in_oa.length) <=> (@@in_oa.index(y.class.name)?@@in_oa.index(y.class.name):@@in_oa.length)
        end
      else
        TransportIngressFilter.registered_filters
      end     
    end
    
    def self.out_filters
      if @@out_oa
        return TransportOutgressFilter.registered_filters.sort do |x,y|
            (@@out_oa.index(x.class.name)?@@out_oa.index(x.class.name):@@out_oa.length) <=> (@@out_oa.index(y.class.name)?@@out_oa.index(y.class.name):@@out_oa.length)
        end
      else
        TransportOutgressFilter.registered_filters
      end
    end
    
    def self.clear_all_filters
      TransportIngressFilter.registered_filters.clear
      TransportOutgressFilter.registered_filters.clear
    end
    
    
  end
  
end
