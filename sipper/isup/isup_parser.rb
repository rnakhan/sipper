
require 'isup/isup'

module ISUP
 
  class IsupParser
    
    @msg_type = {"01"=>"IAM", "06"=>"ACM","09"=>"ANM","0C"=>"REL","10"=>"RLC"}
    
    def self.parse(arr)
      msg = arr.join
      msg.chomp!
      type = msg[0 .. 1]
      isup_msg = eval("ISUP::"+@msg_type[type]).new(msg)
      return isup_msg
    end  
  end # class
  
end
