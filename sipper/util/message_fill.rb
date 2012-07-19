require 'sip_logger'

module SipperUtil
  class MessageFill
    
    include SipLogger
    
    @@slog = SipLogger['siplog::messagefill']

    SUBS = {
      :lip => /_PH_LIP_/,
      :lp => /_PH_LP_/,
      :rip => /_PH_RIP_/,
      :rp => /_PH_RP_/,
      :gcnt => /_PH_GCNT_/,        #global accross process
      :lcnts => /_PH_LCNTS_/,      #local seq maintained for session for sent msg
      :lcntr => /_PH_LCNTR_/,      #local maintained for session for recvd msg
      :lctg => /_PH_LCTG_/,        #local tag
      :trans => /_PH_TRANS_/,      #transport UDP/TCP/TLS/SCTP
      :cl  => /_PH_CL_/,           #content length 
      :rnd => /_PH_RND_/           # random string
    }
    
    # just plain strings
    def MessageFill.sub(str, h)
      k = nil
      v = nil
      h.each do |k,v|
        str.gsub!(SUBS[k], v)
      end
      str
    end
    
    def MessageFill.fill(msg, h)
      @@slog.debug("msg is a #{msg.class}") if @@slog.debug?
      return MessageFill.sub(msg, h) if msg.is_a?(String)
      str = nil
      k = nil
      v = nil
      msg.each do |k, v|
        #SipLogger['siplog::messagefill'].debug("Processing for #{k} the value is #{v}")
        unless v.nil?         
          msg[k] = v.map do |e|
            case e
            when String  
              MessageFill.sub(e, h) 
            when ::SipHeaders::Header
              str = e.to_s
              if  str =~ /_PH_/
                e.assign(MessageFill.sub(str, h))
              else
                e
              end
            else
              raise TypeError, "#{e.class} is not an acceptable type for message fill"
            end   # case
          end     # map
        end       # v.nil?
        @@slog.debug("Processed for #{k} the value is #{msg[k]}") if @@slog.debug?
      end         # each
    end
    
    
  end
end
