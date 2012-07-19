
require 'driven_sip_test_case'

class TestRefer < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestRefer_SipInline
      class Uas2xxController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        session_timer 1500

        def on_refer(session)
          logd("Received Refer in #{name}")

          subscription = session.get_subscription(session.irequest)

          if subscription == nil
             logd("New subscription received.")
             subscription = session.create_subscription_from_request(session.irequest)
          end

          response = session.create_response(202)
          session.send_response(response)

          notifyReq = session.create_subsequent_request("NOTIFY")
          session.add_subscription_to_request(notifyReq, subscription)
          notifyReq.content = "SIP/2.0 100 Trying\r\n"
          notifyReq.content_type = "message/sipfrag;version=2.0"

          session.send_request(notifyReq)
        end

        def on_success_res(session)
          logd("Received response in #{name}")

          request = session.iresponse.get_request()
          subscription = session.get_subscription(request)

          if subscription.state == "terminated"
             session.remove_subscription(subscription)
             session.invalidate
             session.flow_completed_for("TestRefer")  
          else
             subscription.state = "terminated"
             notifyReq = session.create_subsequent_request("NOTIFY")
             session.add_subscription_to_request(notifyReq, subscription)
             notifyReq.content = "SIP/2.0 200 OK\r\n"
             notifyReq.content_type = "message/sipfrag;version=2.0"

             session.send_request(notifyReq)
          end
        end

        def order
          0
        end
      end
      
      class Uac2xxController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          r = Request.create_initial("refer", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          subscription = u.create_subscription("refer")
          u.add_subscription_to_request(r, subscription)
          u.send(r)
          logd("Sent a new REFER from #{name}")
        end
     
        def on_notify(session)
          logd("Received notify in #{name}")

          subscription = session.get_subscription(session.irequest)

          if subscription == nil
             logd("Unsolicited notify received.")
             session.respond_with(200)
             return
          end

          session.respond_with(200)

          subscription = session.update_subscription(session.irequest)

          if subscription.state == "terminated"
             session.invalidate
          end
        end

        def on_success_res(session)
          logd("Received response in #{name}")
        end
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestRefer_SipInline::Uac2xxController")
  end
  
  
  def test_subscribe_notify
    self.expected_flow = ["> REFER","< 202 {0,}", "< NOTIFY", "< 202 {0,}", "> 200", "< NOTIFY", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< REFER","> 202", "> NOTIFY", "< 200", "> NOTIFY", "< 200"]
    
    verify_call_flow(:in)
  end
  
end


