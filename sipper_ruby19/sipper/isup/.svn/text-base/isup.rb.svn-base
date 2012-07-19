module ISUP
  
  class IAM
    def initialize(hexdump=nil)
      @type = "IAM"
      
      if hexdump !=nil
        hexdump.chomp!
        hexdump.delete!(" ")
        @msg_content = hexdump
      else
        #default content
        @msg_content = "01 00 00 00 00 00 02 00 03 80 00 00".delete!(" ")
      end
        
    end  
      
    def  msg_type
      @type
    end
    
    def  contents
      @msg_content
    end
     
    def  natConInd
      #First parameter : nat of conn ind., size 1 octet
      @msg_content.slice(2 .. 3)  
    end
    
    def  natConInd=(val)
      @msg_content[2 .. 3] = val  
    end
    
    def  fwdCallInd
      #second parameter : Fwd call ind., size 2 octet
      @msg_content.slice(4 .. 7)  
    end
    
    def  fwdCallInd=(val)
      @msg_content[4 .. 7] = val  
    end
    
    def  callingPartyCat
      #Third parameter : calling party category, size 1 octet
      @msg_content.slice(8 .. 9)  
    end
    
    def  callingPartyCat=(val)
      @msg_content[8 .. 9] = val  
    end
    
    def  transMedReq
      #Fourth parameter : Transmission medium requirement, size 1 octet
      @msg_content.slice(10 .. 11)  
    end
    
    def  transMedReq=(val)
      @msg_content[10 .. 11] = val  
    end
    
    def calledPartyNumber
      calledPartyNumber=""
      ptrCalledPartyNb = @msg_content.slice(12 .. 13).to_i(16)
      len = @msg_content.slice(14+ptrCalledPartyNb .. 14+ptrCalledPartyNb+1 ).to_i(16)
      oddEvenInd = @msg_content.slice(14+ptrCalledPartyNb+2,2 ).to_i(16)
      addr_signal= @msg_content.slice(14+ptrCalledPartyNb+6, len*2-4)
      #Digits reading
      #length - 2 : without the last octets
      i = 0
      ((addr_signal.length-2)/2).times do
      calledPartyNumber << addr_signal[i,2].reverse
      i += 2
      end
      #Last octet : 1 or 2 digits to read according to odd/even ind
      if oddEvenInd >= 128 #eigth bit is 1
        calledPartyNumber << addr_signal[i+1]
      else
        calledPartyNumber << addr_signal[i,2].reverse
      end
      calledPartyNumber     
    end  
    
    def calledPartyNumber=(val)
      calledPartyNumber=""
      i = 0
      ((val.length-1)/2).times do
      calledPartyNumber << val[i,2].reverse
      i += 2
      end
      if val.length % 2 == 0
        calledPartyNumber << val[i,2].reverse
      else
        calledPartyNumber << "0"
        calledPartyNumber << val[i]  
      end
      ptrCalledPartyNb = @msg_content.slice(12 .. 13).to_i(16)
      len = @msg_content.slice(14+ptrCalledPartyNb .. 14+ptrCalledPartyNb+1 ).to_i(16)
      
      #set the lenth octect
      @msg_content[14+ptrCalledPartyNb .. 14+ptrCalledPartyNb+1] = (val.length/2.0 + 2).round.to_s(16).rjust(2,"0")
      #set the odd even bit
      oddEvenOctet = @msg_content.slice(14+ptrCalledPartyNb+2,2 ).to_i(16)
      if val.length % 2 != 0 
        binaryRepr = oddEvenOctet.to_s(2).rjust(8,"0")
        binaryRepr[0]="1"
        newVal = (binaryRepr.to_i(2)).to_s(16)
        @msg_content[14+ptrCalledPartyNb+2,2] = newVal
      end  
      #set the called party number
      @msg_content[14+ptrCalledPartyNb+6, len*2-4] = calledPartyNumber        
    end  
  end
  
  class ACM
    def initialize(hexdump=nil)
      @type = "ACM"
      
      if hexdump !=nil
        hexdump.chomp!
        hexdump.delete!(" ")
        @msg_content = hexdump
      else
        #default content
        @msg_content = "06 00 00 00".delete!(" ")
      end
        
    end  
    
    def  msg_type
      @type
    end
    
    def  contents
      @msg_content
    end
    
    def  bckCalInd
      #First parameter : backward call indicator., size 2 octet
      @msg_content.slice(2 .. 5)  
    end
    
    def  bckCalInd=(val)
      @msg_content[2 .. 5] = val  
    end
  end
  
  class ANM
    def initialize(hexdump=nil)
      @type = "ANM"
      
      if hexdump !=nil
        hexdump.chomp!
        hexdump.delete!(" ")
        @msg_content = hexdump
      else
        #default content
        @msg_content = "09 00".delete!(" ")
      end
    end
    
    def  msg_type
      @type
    end
    
    def  contents
      @msg_content
    end
    
  end


  class REL
    def initialize(hexdump=nil)
      @type = "REL"
      
      if hexdump !=nil
        hexdump.chomp!
        hexdump.delete!(" ")
        @msg_content = hexdump
      else
        #default content
        @msg_content = "0C 02 00 03 80 81 80".delete!(" ")
      end
    end  
    
    def  msg_type
      @type
    end
    
    def  contents
      @msg_content
    end
    
    def causeVal
      ptrCauseInd = @msg_content.slice(2 .. 3).to_i(16)
      #len = @msg_content.slice(4+ptrCauseInd .. 4+ptrCauseInd+1 ).to_i(16)
      extInd2 = @msg_content.slice(4+ptrCauseInd+4,2 ).to_i(16)
      # cause value parameter iis a decimal number
      causeVal = extInd2.to_s(2)[1 .. 7].to_i(2)
      causeVal
    end
    
    def  causeVal=(val)
      ptrCauseInd = @msg_content.slice(2 .. 3).to_i(16)
      extInd2 = @msg_content.slice(4+ptrCauseInd+4,2 ).to_i(16)
      if extInd2 >= 128
        @msg_content[4+ptrCauseInd+4,2] = ("1" + val.to_s(2).rjust(7,"0")).to_i(2).to_s(16)
      else
        @msg_content[4+ptrCauseInd+4,2] = ("0" + val.to_s(2).rjust(7,"0")).to_i(2).to_s(16)
      end  
    end
  end


  class RLC
    def initialize(hexdump=nil)
      @type = "RLC"
      
      if hexdump !=nil
        hexdump.chomp!
        hexdump.delete!(" ")
        @msg_content = hexdump
      else
        #default content
        @msg_content = "10 00".delete!(" ")
      end
    end
    
    def  msg_type
      @type
    end
    
    def  contents
      @msg_content
    end
    
  end

end
