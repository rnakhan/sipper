require 'base_controller'

module SipMessage
  class UasMsgController < SIP::BaseController
    
     def on_message(session)
       logd("Received MESSAGE in #{name}")
       session.local_tag = 5  #todo differentiate automatically on the same container somehow
       r = session.create_response(200, "OK")
       session.send(r)
       session.invalidate(true)
     end
  end
end