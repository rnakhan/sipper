require 'base_controller'

module InfoTest
  class UasInfoController < SIP::BaseController
    
     def on_info(session)
       logd("Received #{session.irequest.method} in #{name}")
       session.local_tag = 5  #todo differentiate automatically on the same container somehow
       r = session.create_response(200, "OK")
       session.send(r)
       session.invalidate(true)
     end
     
  end
end