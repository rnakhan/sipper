module SIP
  module Validations
  
    def validate_presence_of_headers(*hdr_names)
      hdr_names.each do |hdr|
        if self.imessage[hdr]
          self.do_record("true")
        else
          self.do_record("header #{hdr} not found in the message")
        end
      end
    end
    
    def validate_header_values(hdr_val_hash)
      hdr_val_hash.each do |k,v|
        if self.imessage[k]
          mvh = v.split(",").sort
          if mvh == self.imessage[k].sort
            self.do_record("true")
          else
            self.do_record("actual header value found is #{self.imessage[k]}")
          end
        else
          self.do_record("header #{k} not found in the message")
        end
      end
    end
    
    def validate_presence_of_header_params(hdr_name, *params)
      if hdr=self.imessage[hdr_name]
        params.each do |p|
          if hdr[0].send p.to_sym
            self.do_record("true")
          else
            self.do_record("param #{p} not found on #{hdr_name}") 
          end 
        end
      else
        self.do_record("header #{hdr_name} not found in the message")
      end
    end
    
  end
end
