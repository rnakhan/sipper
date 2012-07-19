require 'base_controller'

class TestuasController < SIP::SipTestDriverController 

  transaction_usage :use_transactions=>false

  def initialize
    logd('Controller created')
  end

  def session_being_invalidated_ok_to_proceed?(session)
     false
  end

  def on_invite(session)
    session.respond_with(100)
    session.respond_with(200)
  end

  def on_bye(session)
    session.update_audio_spec(:play_spec=>'', :rec_spec=>'')
    session.respond_with(200)
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
  end

  def on_ack(session)
    sleep 1    
    if session.irequest.from.display_name.to_s == '"123"'      # Checking for whether the caller is subscriber or not. (subscriber name is "123")
        session.update_audio_spec(:play_spec=>'PLAY greeting.au')
    else  
      session.update_audio_spec(:play_spec=>'PLAY welcome.au, SLEEP 2',:rec_spec=>'')
      sleep 5
      session.update_audio_spec(:play_spec=>'', :rec_spec=>'./mailbox/voicemail.au')
    end  
  end
  
  def on_media_dtmf_received(session)
    num = session.imedia_event.dtmf.to_i
    session.update_audio_spec(:play_spec=>'PLAY ./mailbox/voicemail.au') if num == 1   # Plays the voicemail after pressing the dtmf key 1
  end
end
