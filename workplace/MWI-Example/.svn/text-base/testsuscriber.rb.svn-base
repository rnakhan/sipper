$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class TestSubscriber < DrivenSipTestCase

  def setup
    super
    
    str = <<-EOF
    
require 'sip_test_driver_controller'
  
  class SubscriberController < SIP::SipTestDriverController
    transaction_usage :use_transactions=>false  
    session_limit 150000
            
    def start
      r = Request.create_initial("SUBSCRIBE", "sip:joe@example.com", :p_session_record=>"msg-info")
      u = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
      subscription = u.create_subscription("message-summary")
      u.add_subscription_to_request(r, subscription)
      r.expires = "86400"
      u.send(r)
    end
 
    def on_notify(session)
      if !session['notify']
        session.respond_with(200)
        session['notify'] = 1
      elsif session['notify'] == 1
        session.respond_with(200)
        session.invalidate(true)
        session.flow_completed_for("TestSubscriber")
      end
    end
  end
  
    EOF
    define_controller_from(str)
    set_controller("SubscriberController")
  end
  
  
  def test_subscriber
    self.expected_flow = ["> SUBSCRIBE","< 200", "< NOTIFY", "> 200", "< NOTIFY", "> 200"]
    start_controller
    verify_call_flow(:out)
  end
  
end  