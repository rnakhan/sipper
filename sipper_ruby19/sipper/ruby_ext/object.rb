
# Extension to flatten the classname to make it amenable
# to logging.

class Object
  def class_name
    begin
      self.classname
    rescue NoMethodError
      name = self.class.name.split("::").join("_")
      self.class.class_eval do
        define_method(:classname) {
          name
        }
      end
      retry
    end #rescue
  end  #method
  
  
  def is_request?
    self.class == Request
  end
  
  def is_response?
    self.class == Response
  end
  
  # clears the given instance variables as symbols arrays
  # e.g  o.clear_ivs([:@a, :@b]) sets the instance variable @a and @b to nil
  # in the object o. 
  def clear_ivs(arr)
    arr.each do |i|
      instance_variable_set(i, nil)
    end
  end
  
end