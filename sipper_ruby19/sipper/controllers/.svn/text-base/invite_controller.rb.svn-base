require 'base_controller'

class InviteController < SIP::BaseController

   transaction_usage :use_transactions=>true
   
   def initialize
     @ilog = logger
     @ilog.debug("#{name} controller created") if @ilog.debug?
   end
   
   
   def on_invite(session)
     @ilog.debug("on_invite called for #{name}") if @ilog.debug?
     r = session.create_response(200, "OK")
     r.server = "Sipper"
     session.send(r)
   end
   
   
   def on_ack(session)
     @ilog.debug("on_ack called for #{name}") if @ilog.debug?
   end
   
   def on_bye(session)
     @ilog.debug("on_bye called for #{name}, now invalidating") if @ilog.debug?
     r = session.create_response(200, "OK")
     session.send(r)
     session.invalidate(true)
   end
end
