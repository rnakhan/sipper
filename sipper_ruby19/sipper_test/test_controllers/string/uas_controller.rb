require 'base_controller'

module StringRecord

  class UasController < SIP::BaseController
  
     def initialize
       logd("#{name} controller created")
     end
     
     
     def on_info(session)
       logd("on_info called for #{name}")
       session.local_tag = 5  #todo differentiate the key for UAC/UAS
       r = session.create_response(200, "OK")
       session.send(r)
       session.invalidate(true)
     end
     
  end

end