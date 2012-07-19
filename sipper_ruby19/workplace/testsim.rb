require 'sip_test_driver_controller'
require 'cgi'

class TestmediacontrollerController < SIP::SipTestDriverController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>true

  def initialize
    logd('Controller created')
  end


  def on_invite(s)
    s["responseurl"] = CGI::unescape(s.irequest.uri.split("responseurl=")[1])

    s.set_media_attributes(:codec=>['G711U', 'DTMF'],
      :type=>'SENDRECV',
      :play=>{:file=>'hello_sipper.au', :repeat=>true},
      :record_file=>'in_sipper.au',
      :remote_m_line=>['any'])
    s.respond_with(200)
  end
  
  def on_media_connected(session)
    puts "NK **** Media started**"
  end
    
    def on_media_disconnected(session) 
      puts "NK **** Media stopped**"
    end
    
    def on_media_dtmf_received(session)
      puts "NK*********DTMF key received****"+session.imedia_event.dtmf

      if session.imedia_event.dtmf == "1"
         session.send_http_post_to(s["responseurl"], 'command' => 'Transfer', 'target' => '1002')
      end
    end

  def on_ack(session)
  end

  def on_bye(session)
     session.respond_with(200)
  end
end
