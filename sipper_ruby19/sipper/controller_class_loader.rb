require 'sip_logger'
require 'ruby_ext/string'

module SIP
  class ControllerClassLoader
    
    @@class_constants = []
    
    def self.clear_all
      @@class_constants = []
    end
    
    def self.load fpath
      str = IO.read(fpath)
      load_from_string(str)
    end
    
    def self.load_from_string(str)
      @@class_constants += str.all_class_names.select {|x| x=~ /Controller/}  # re-opened string in ruby_ext
      Object.module_eval(str)  # load it in top level too. (could also be Kernel.load(path)
    end
    
    def self.controllers 
      SipLogger['siplog::sip_controllerclassloader'].debug("Controllers now are #{@@class_constants.uniq.join(',')} ") 
      @@class_constants.uniq
    end
    
  end
end
