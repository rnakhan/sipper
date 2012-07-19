$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class Testuas < DrivenSipTestCase 

  SipperConfigurator[:SipperMedia]='true'
  def self.description
    "Callflow is < INVITE, > 100, > 200, < ACK, < BYE, > 200" 
  end

  def setup
    super
    SipperConfigurator[:SessionRecord]='msg-info'
    SipperConfigurator[:WaitSecondsForTestCompletion] = 1800
    SipperConfigurator[:SessionLimit] = 3600000
    str = <<-EOF
# FLOW : < INVITE, > 100, > 200, < ACK, < BYE, > 200
#
require 'base_controller'

class TestuasController < SIP::SipTestDriverController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

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
    session.respond_with(200)
    session.invalidate(true)
    session.flow_completed_for('Testuas')
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
  end

  def on_ack(session)
  end
  
  
  def on_media_connected(session)
    puts "NK **** Media started**"
  end
  
  def on_media_disconnected(session) 
      puts "NK **** Media stopped**"
  end
    
  
  def on_media_dtmf_received(session)
      num = session.imedia_event.dtmf
      puts "NK*********DTMF key received****"+session.imedia_event.dtmf

      session.update_dtmf_spec(:dtmf_spec => "3,sleep 2,4,sleep 2, 5") if num == '0'
      session.update_audio_spec(:play_spec=>'', :rec_spec=>'suriya.au') if num == '1'
      session.update_audio_spec(:play_spec=>'PLAY suriya.au,SLEEP 2,PLAY_REPEAT suriya.au 2', :rec_spec=>'') if num == '2'
  end
end
    EOF
    define_controller_from(str)
    set_controller('TestuasController')
  end

  def test_case_1
    self.expected_flow = ['< INVITE','> 100','> 200','< ACK','< BYE','> 200']
    start_controller
    verify_call_flow(:in)
  end
end
