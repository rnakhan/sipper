require 'sip_test_driver_controller'
    
  class MwiController < SIP::SipTestDriverController
      
    transaction_usage :use_transactions=>false
    session_limit 150000

    def on_subscribe(session)
      session[:subs_req] = session.irequest
      subscription = session.get_subscription(session.irequest)
      if subscription == nil
        subscription = session.create_subscription_from_request(session.irequest)
      else
        subscription = session.update_subscription(session.irequest)
      end
      session.respond_with(200)

      notifyReq = session.create_subsequent_request("NOTIFY")
      session.add_subscription_to_request(notifyReq, subscription)
      notifyReq.expires = "3599"
      notifyReq.content_type = "application/simple-message-summary"
      notifyReq.content = "Message-Waiting: no"
      session.send_request(notifyReq)
      session.schedule_timer_for("t1_timer", 5000) 
    end
  
    def on_timer(session, task) 
      if File.exist?("./mailbox//voicemail.au")
        notifyReq = session.create_subsequent_request("NOTIFY")
        subscription = session.get_subscription(session[:subs_req])
        session.add_subscription_to_request(notifyReq, subscription)
        notifyReq.expires = "3599"
        notifyReq.content_type = "application/simple-message-summary"
        notifyReq.content = "Message-Waiting: yes
        Voice-Message: 1"        
        session.send(notifyReq)  
      end  
      session.schedule_timer_for("t1_timer", 5000)
    end
    
  end


