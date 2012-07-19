#          PUA                                PA                      WATCHER
#         (EPA)                            (ESC)
#           |                                 |                                     |
#           |                                 | <---- M1: SUBSCRIBE --- |
#           |                                 |                                     |
#           |                                 | ----- M2: 200 OK ----->    |
#           |                                 |                                     |
#           |                                 | ----- M3: NOTIFY ----->  |
#           |                                 |                                     |
#           |                                 | <---- M4: 200 OK ------    |
#           |                                 |                                     |
#           |                                 |                                     |
#           | ---- M5: PUBLISH --->|                                     |
#           |                                 |                                     |
#           | <--- M6: 200 OK ----   |                                     |
#           |                                 |                                     |
#           |                                 | ----- M7: NOTIFY -----> |
#           |                                 |                                    |
#           |                                 | <---- M8: 200 OK ------   |
#           |                                 |                                    |
#           | ---- M9: PUBLISH ---> |                                    |
#           |                                 |                                    |
#           | <--- M10: 200 OK ---   |                                    |
#           |                                 |                                    |
#           |                                 |                                    |
#           | --- M11: PUBLISH ---> |                                    |
#           |                                 |                                    |
#           | <-- M12: 200 OK ----   |                                    |
#           |                                 |                                    |
#           |                                 | ----- M13: NOTIFY ----> |
#           |                                 |                                    |
#           |                                 | <---- M14: 200 OK -----  |
#           |                                 |                                    |
require 'driven_sip_test_case'

class TestPublish < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestPublish_SipInline
    
        class EPAController < SIP::SipTestDriverController
      
      transaction_usage :use_transactions=>false
      
      
      session_timer 1500

        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("PUBLISH", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          subscription = u.create_subscription("presence")
          u.add_subscription_to_request(r, subscription)
          r.expires = "3600"
          r.content_type = "application/pidf+xml"
          r.content = "Published PIDF document\r\n"
          u.send(r)
          logd("Sent a new Publish from #{name}")
        end
        
        def on_success_res(session)
          if !session['2xx'] 
            r = session.create_subsequent_request("PUBLISH", "sip:nasir@sipper.com")
            subscription = session.create_subscription("presence")
            session.add_subscription_to_request(r, subscription)
            r.expires = "3600"
            r.sip_if_match = session.iresponse.sip_etag.to_s
            session.send(r)    
            session['2xx'] = 1
          elsif session['2xx'] == 1
            r = session.create_subsequent_request("PUBLISH", "sip:nasir@sipper.com")
            subscription = session.create_subscription("presence")
            session.add_subscription_to_request(r, subscription)
            r.expires = "3600"            
            r.sip_if_match = session.iresponse.sip_etag.to_s 
            r.content_type = "application/pidf+xml"
            r.content = "Published PIDF document\r\n"            
            session.send(r)
            session['2xx'] = 2
          elsif session['2xx'] == 2
            session.invalidate(true)
          end  
        end
                
      end
    
        
      class ESCController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        
        
        session_timer 1500

        def on_publish(session)
          if !session['publish']
            r = session.create_response(200)
            r.sip_etag = "dx200xyz"
            r.expires = "1800"
            session.send(r)
            session['publish'] =1 
          elsif session['publish'] == 1
            r = session.create_response(200)
            r.sip_etag = "kwj449x"
            r.expires = "1800"
            session.send(r)
            session['publish'] =2
          elsif session['publish'] == 2
            r = session.create_response(200)
            r.sip_etag = "qwi982ks"
            r.expires = "3600"
            session.send(r)
            session.invalidate(true)
          end 
          
          if session.irequest.content_length.header_value.to_i > 0
            dialog_info = dialog_store.get("watcherSession")
            dialog = dialog_info.split(',')  
            watcherSession = SessionManager.find_session(dialog[0], dialog[1], dialog[2])
            msg = CustomMessage.new
            watcherSession.post_custom_message(msg)
          end  
        end
        
        def on_custom_msg(watcherSession, msg)
          logd("Received Custom message in "+ name)
          notifyReq = watcherSession.create_subsequent_request("NOTIFY")
          subscription = watcherSession.get_subscription(watcherSession[:subs_req])
          watcherSession.add_subscription_to_request(notifyReq, subscription)
          notifyReq.expires = "3599"
          notifyReq.content = "PIDF document\r\n"
          notifyReq.content_type = "application/pidf+xml"
          watcherSession.send(notifyReq)  
        end

        
        def on_subscribe(session)
          logd("Received Subscribe in #{name}")
          session[:subs_req] = session.irequest
          subscription = session.get_subscription(session.irequest)
          if subscription == nil
             logd("New subscription received.")
             subscription = session.create_subscription_from_request(session.irequest)
          else
             logd("Subscription refresh received.")
             subscription = session.update_subscription(session.irequest)
          end
          
          response = session.create_response(200)
          session.send_response(response)

          notifyReq = session.create_subsequent_request("NOTIFY")
          session.add_subscription_to_request(notifyReq, subscription)
          notifyReq.expires = "3599"
          notifyReq.content = "PIDF document\r\n"
          notifyReq.content_type = "application/pidf+xml"

          session.send_request(notifyReq)

          dialog_info = session.call_id + "," + session.local_tag + "," + session.remote_tag  
          dialog_store.put("watcherSession", dialog_info) 
        end

        def on_success_res(session)
          logd("Received response in #{name}")
          if !session['2xx']
            session['2xx'] =1 
          elsif session['2xx'] ==1
            session['2xx'] = 2
          elsif session['2xx'] ==2  
            dialog_store.delete("watcherSession")
            session.invalidate
            session.flow_completed_for("TestPublish")  
          end
        end

        def order
          0
        end
      end
      
      class WatcherController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        session_timer 500
        
        def start
          r = Request.create_initial("subscribe", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          subscription = u.create_subscription("presence")
          u.add_subscription_to_request(r, subscription)
          r.expires = "3600"
          u.send(r)
          logd("Sent a new Subscribe from #{name}")
        end
     
        def on_notify(session)
          if !session['notify']
          session.respond_with(200)
          session['notify'] = 1
         elsif session['notify'] == 1
          session.respond_with(200)
          session['notify'] = 2
         elsif session['notify'] == 2
          session.respond_with(200)
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
  end
  
  
  def test_publish
    self.expected_flow = ["> SUBSCRIBE","< 200", "< NOTIFY", "> 200", "< NOTIFY", "> 200", "< NOTIFY", "> 200"]
    start_named_controller_non_blocking("TestPublish_SipInline::WatcherController")
    sleep 1
    start_named_controller("TestPublish_SipInline::EPAController")
    verify_call_flow(:out,0)
    
    self.expected_flow = ["> PUBLISH", "< 200", "> PUBLISH", "< 200", "> PUBLISH", "< 200"]
    verify_call_flow(:out,1)
    self.expected_flow = ["< SUBSCRIBE","> 200", "> NOTIFY", "< 200", "> NOTIFY", "< 200", "> NOTIFY", "< 200"]
    verify_call_flow(:in,0)
    self.expected_flow = ["< PUBLISH", "> 200", "< PUBLISH", "> 200", "< PUBLISH", "> 200"]
    verify_call_flow(:in,1)
  end
  
end


