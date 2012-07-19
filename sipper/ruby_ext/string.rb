require 'util/sipper_util'
require 'sip_headers/header'
require 'ruby_ext/module'

class String
  
  # extension to read class names from a string containing class definitions 
  def all_class_names
    mod = Module.new
    mod.module_eval(self)
    mod.all_class_names
  end
  
  def int?
    /^-?\d+$/ === self
  end
  
end
