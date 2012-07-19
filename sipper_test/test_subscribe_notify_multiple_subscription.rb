
require 'driven_sip_test_case'

class TestSubscribeNotifyMultipleSubscription < DrivenSipTestCase

  def setup
    super
    str = <<-EOF

    require 'sip_test_driver_controller'
    
    module TestSubscribeNotifyMultipleSubscription_SipInline
      class Uas2xxController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        t2xx_usage true
        
        t1xx_timers :Start=>100
        
        session_timer 1500

        def on_subscribe(session)
          logd("Received Subscribe in #{name}")

          subscription = session.get_subscription(session.irequest)

          if subscription == nil
             logd("New subscription received.")
             subscription = session.create_subscription_from_request(session.irequest)
             currcount = session["numOfSubscription"].to_i
             currcount = currcount + 1
             session["numOfSubscription"] = currcount.to_s
          else
             logd("Subscription refresh received.")
             subscription = session.update_subscription(session.irequest)
          end

          response = session.create_response(202)
          session.send_response(response)

          session.start_subscription_expiry_timer(subscription, response)

          notifyReq = session.create_subsequent_request("NOTIFY")
          session.add_subscription_to_request(notifyReq, subscription)
          notifyReq.content = "message-waiting: no\r\n"
          notifyReq.content_type = "application/simple-message-summary"

          session.send_request(notifyReq)
        end

        def on_subscription_timeout(session, subscription)
          logd("Received Subscription timeout in #{name}")

          subscription.state = "terminated"

          notifyReq = session.create_subsequent_request("NOTIFY")
          session.add_subscription_to_request(notifyReq, subscription)
          notifyReq.content = "message-waiting: no\r\n"
          notifyReq.content_type = "application/simple-message-summary"

          session.send_request(notifyReq)
          session.remove_subscription(subscription)
          currcount = session["numOfSubscription"].to_i
          currcount = currcount - 1
          session["numOfSubscription"] = currcount.to_s
        end

        def on_success_res(session)
          logd("Received response in #{name}")

          if ( session["numOfSubscription"].to_i == 0 )
             session.invalidate
             session.flow_completed_for("TestSubscribeNotifyMultipleSubscription")  
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
          r = Request.create_initial("subscribe", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.use_transactions = true
          subscription = u.create_subscription("message_summary", 5)
          u.add_subscription_to_request(r, subscription)
          r.expires = "1"
          u.send(r)

          logd("Sent a new Subscribe from #{name}")
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
             session.remove_subscription(subscription)
             logd("Removing subscription from UAC")
             if ( session["SubRemoved"] == "yes" )
                session.invalidate
             else
                session["SubRemoved"] = "yes"
             end
          end
        end

        def on_success_res(session)
          logd("Received subscription response in #{name}")
          request = session.iresponse.get_request()
          subscription = session.get_subscription(request)

          if(subscription.event_id == 5)
             subReq = session.create_subsequent_request("SUBSCRIBE")
             subscription = session.create_subscription("new-event-package", 4)
             session.add_subscription_to_request(subReq, subscription)
             subReq.expires = "2"
             session.send(subReq)
          end
        end
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestSubscribeNotifyMultipleSubscription_SipInline::Uac2xxController")
  end
  
  
  def test_subscribe_notify
    self.expected_flow = ["> SUBSCRIBE", "< 202", "> SUBSCRIBE", "< NOTIFY", "> 200", "< 202", "< NOTIFY", "> 200", "< NOTIFY", "> 200", "< NOTIFY", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< SUBSCRIBE", "> 202", "> NOTIFY", "< SUBSCRIBE", "> 202", "> NOTIFY", "< 200  {2,2}", "> NOTIFY", "< 200", "> NOTIFY", "< 200"]
    
    verify_call_flow(:in)
  end
  
end


