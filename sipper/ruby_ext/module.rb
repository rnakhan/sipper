# Extension for finding class names from a string with class definition
class Module
  def all_class_names
    class_names = []
    constants.each do |const_name|
      const = const_get(const_name)
      case const
      when Class
        class_names << const.to_s.split(/::/,2)[1]
      when Module
        class_names += const.all_class_names
      end
    end
    class_names.uniq
  end
  
  # Extension to allow for snap_fields directive in the class of which snapshot is to be
  # taken. This creates a method by name __snap_fields used by snapshot.rb in the class
  # being snapshotted. 
  def snap_fields(*symbols)
    str = "["
    symbols.each {|s| str << ":" << s.to_s <<  "," }
    str << "]"
    module_eval("def __snap_fields() #{str}; end")
  end
 
end
