=begin
$:.unshift File.join(File.dirname(__FILE__),"..")

require 'sipper'



Thread.current[:name] = "MainThread"

 
  s = SIP::Sipper.new( 
    :Ips=>[SipperConfigurator[:LocalSipperIP]],  # though not required to mention as default is same 
  :Ports=>[5060], 
  :ControllerPath=>nil 
)
SipperConfigurator[:ProtocolCompliance] = 'strict'
trap("INT"){ s.stop }  
t = s.start

# dynamically load controller
str = <<-EOF
require 'base_controller'
require 'sip_test_driver_controller'
module MyControllers
  class SimpleController < SIP::BaseController
    def start
      r = Request.create_initial("info", "sip:nasir@codepresso.com", :allow=>"INVITE", :require=>"100rel")
      r.add_allow("BYE").push_allow("OPTIONS")
      r.add_require("dialog")
      r.format_as_separate_headers_for_mv(:allow, :require)
      u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
      u.send(r)
    end
  end
  
  class UasMsgController < SIP::SipTestDriverController
    session_timer 100
    def on_message(session)
      session.local_tag = 5 
      r = session.create_response(200, "OK")
      session.send(r)
    end
    
    def on_cleanup(session) 
      session.invalidate
      session.flow_completed_for("TestRemoteController")
    end
    
    def order
      0
    end
  end
end
EOF
s.load_controller( str )
s.start_controller( "MyControllers::SimpleController")
t.join
=end