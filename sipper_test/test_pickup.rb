# http://www.tools.ietf.org/html/draft-ietf-sipping-service-examples-14#section-2.16
#            Alice          Bob                Bill
#             |              |                   |
#             |   INVITE F1  |                   |
#             |------------->|                   |
#             |180 Ringing F2|                   |
#             |<-------------|                   |
#             |              |   SUBSCRIBE F3    |
#             |              |<------------------|
#             |              |     200 OK F4     |
#             |              |------------------>|
#             |              |     NOTIFY F5     |
#             |              |------------------>|
#             |              |     200 OK F6     |
#             |              |<------------------|
#             |          INVITE Replaces:Bob  F7 |
#             |<---------------------------------|
#             |              |     200 OK F8     |
#             |--------------------------------->|
#             |   CANCEL F9  |                   |
#             |------------->|                   |
#             |  200 OK F10  |                   |
#             |<-------------|                   |
#             |    487 F11   |                   |
#             |<-------------|                   |
#             |    ACK F12   |                   |
#             |------------->|                   |
#             |                    ACK F13       |
#             |<---------------------------------|
#             |                                  |
#             |    Two way RTP Established       |
#             |<================================>|
#             |                     BYE F14      |
#             |--------------------------------->|
#             |                   200 OK F15     |
#             |<---------------------------------|
#             |                                  |

require 'driven_sip_test_case'


class TestPickup < DrivenSipTestCase

  def setup
    SipperConfigurator[:ControllerPath] = nil
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module TestPickup_SipInline

      class BillController < SIP::SipTestDriverController

        def interested?(req)
           false
        end

        def start
          bill_sub_session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          bill_sub_session.name = "bill_sub_session"
          r = Request.create_initial("subscribe", "sip:bob@sipper.com", :p_session_record=>"msg-info")
          subscription = bill_sub_session.create_subscription("dialog")
          bill_sub_session.add_subscription_to_request(r, subscription)
          r.expires = "0"
          bill_sub_session.send(r)
          logd("Sent a new Subscribe from #{name}")
        end

       
        def on_notify(bill_sub_session)
          content = bill_sub_session.irequest.content
          tag_ary = {}
          content.split("::").each {|val|
            nv=val.split("=")
            tag_ary[nv[0]] = nv[1] if nv && nv[0] && nv[1]
          }

          logd("Received notify Content: " + content.to_s)
          logd("parsed notify Content: " + tag_ary.to_s)
          bill_sub_session.respond_with(200)
          bill_sub_session.invalidate(true)

          bill_session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          bill_session.name = "bill_session"

          r = bill_session.create_initial_request("invite", "sip:alice@sipper.com", :p_session_record=>"msg-info")
          r.replaces = tag_ary["call_id"]
          r.replaces["from-tag"] = tag_ary["local_tag"]
          r.replaces["to-tag"] = tag_ary["remote_tag"]
          r.replaces["early-only"] = ''      
          bill_session.send(r)
          logd("Sent a new Invite with replaces from " + name)  
        end

        def on_success_res(bill_session)
          logd("Received response in "+name)
          bill_session.create_and_send_ack
        end

        def on_bye(bill_session)
          bill_session.respond_with(200)
          bill_session.invalidate(true)
        end
      end

      class BobController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
       
        session_timer 1500

        def interested?(req)
          (req.method == "INVITE" && !req[:replaces]) ||
          (req.method == "SUBSCRIBE")
        end
        
        def on_invite(bob_session1)
          bob_session1.name = "bob_session1"
          bob_session1.respond_with(180)

          dialog_info = "local_tag=" + bob_session1.local_tag + 
                                   "::remote_tag=" + bob_session1.remote_tag + 
                                   "::call_id=" + bob_session1.call_id
          dialog_store.put(bob_session1.irequest.uri.to_s, dialog_info)                         
        end

        def on_cancel(bob_session1)
           logd("Received cancel request in #{name}")
           # Here we use the To header because the Contact in 180 changes
           # remote target.
           dialog_store.delete(bob_session1.irequest.to.uri.to_s)
           bob_session1.invalidate(true)
        end

        def on_subscribe(session)
          subscription = session.get_subscription(session.irequest)
          session.name = "bob_session2"
          if subscription == nil
             logd("New subscription received.")
             subscription = session.create_subscription_from_request(session.irequest)
          else
             logd("Subscription refresh received.")
             subscription = session.update_subscription(session.irequest)
          end

          response = session.create_response(202)
          session.send_response(response)

          subscription.state = "terminated"
          
          dialog_info = dialog_store.get(session.irequest.uri.to_s)

          notifyReq = session.create_subsequent_request("NOTIFY")
          session.add_subscription_to_request(notifyReq, subscription)
          notifyReq.content = dialog_info
          notifyReq.content_type = "application/dialog-info+xml"

          session.send_request(notifyReq)
        end

        def on_success_res_for_notify(session)
           session.invalidate(true)
        end
      end
   
      
      class AliceController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>true        
        session_timer 500
        
        def interested?(req)
          req[:replaces]
        end
        
        def start
          logd("Alice controller Started. Suriya")
          alice_session1 = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          alice_session1.name = "alice_session1"
          alice_session1.request_with('INVITE', 'sip:bob@sipper.com', :to=>'sip:bob@sipper.com', :p_session_record=>"msg-info" )
          logd("Sent a new Invite from " +name)
        end
     
        def on_invite(alice_session2)
          alice_session2.name = "alice_session2"
          if alice_session2.irequest[:replaces] != nil
             r = alice_session2.irequest
             callid = r.replaces.header_value
             localtag = r.replaces["to-tag"]
             remotetag = r.replaces["from-tag"]
             alice_session1 = SessionManager.find_session(callid, localtag, remotetag)
             alice_session1.post_custom_message(CustomMessage.new)
          end  
          alice_session2.respond_with(200)
        end
        
        def on_custom_msg(alice_session1, msg)
          logd("Received Custom message in "+ name)
          alice_session1.create_and_send_cancel_when_ready
        end
        
        def on_failure_res(alice_session1)
          logd("Received failure response in "+ name)
          alice_session1.invalidate(true)
        end

        def on_ack(alice_session2)
          logd("Received ACK in "+ name)
          alice_session2.schedule_timer_for(:endCall, 100)
        end

        def on_timer(alice_session2, timertask)
          req = alice_session2.create_subsequent_request('BYE')
          alice_session2.send(req)
        end

        def on_success_res(session)
          if session.iresponse.get_request_method == "BYE"
             logd("End of call flow reached.")
             alice_session2 = session
             alice_session2.invalidate(true)
             alice_session2.flow_completed_for("TestPickup")
          end
        end
      end
    end
    EOF
    define_controller_from(str)
  end
  
  
  def test_pickup
    start_named_controller_non_blocking("TestPickup_SipInline::AliceController")
    start_named_controller_non_blocking("TestPickup_SipInline::BillController")
    wait_for_signaling
    # alice_session1
    self.expected_flow = ["> INVITE","< 100", "< 180", "> CANCEL", "< 200", "< 487", "> ACK"]
    verify_call_flow(:out, 0)

    self.expected_flow = ["< INVITE","> 100", "> 180", "< CANCEL", "> 200", "> 487", "< ACK"]
    verify_call_flow(:in, 0)

    self.expected_flow = ["< SUBSCRIBE", "> 202", "> NOTIFY", "< 200"]
    verify_call_flow(:in, 1)

    self.expected_flow = ["> SUBSCRIBE", "< 202", "< NOTIFY", "> 200"]
    verify_call_flow(:out, 1)

    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    verify_call_flow(:out, 2)

    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in, 2)
  end

end


