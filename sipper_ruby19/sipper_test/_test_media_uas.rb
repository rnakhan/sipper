require 'driven_sip_test_case'

class Testmediacontroller < DrivenSipTestCase 

  def setup
    @sm = SipperConfigurator[:SipperMedia] 
    SipperConfigurator[:SipperMedia] = true
    super
    SipperConfigurator[:SessionRecord]='msg-info'
    SipperConfigurator[:WaitSecondsForTestCompletion] = 40
    str = <<-EOF
# FLOW : > INVITE, < 200, > ACK
#
require 'base_controller'

class TestmediacontrollerController < SIP::SipTestDriverController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>true

  def initialize
    logd('Controller created')
  end


  def on_register(session)
    session.respond_with(200) 
    registration_store.put(:bob, session.irequest.contact.uri.to_s)
    session.invalidate(true)
  end


  def on_invite(s)
    s.set_media_attributes(:codec=>['G711U', 'DTMF'],
      :type=>'SENDRECV',
      :play=>{:file=>'hello_sipper.au', :repeat=>false},
      :record_file=>'in_sipper.au',
      :remote_m_line=>['any'])
    s.respond_with(200)
  end
  
  def on_subscribe(session)
    session.respond_with(200)
  end

  def on_media_connected(session)
    puts "NK **** Media started**"
  end
    
    def on_media_disconnected(session) 
      puts "NK **** Media stopped**"
    end
    
    def on_media_dtmf_received(session)
      puts "NK*********DTMF key received****"+session.imedia_event.dtmf
    end

  def on_ack(session)
    #sleep 15
    #session.invalidate
    #session.flow_completed_for('Testmediacontroller')
  end

end
    EOF
    define_controller_from(str)
    set_controller('TestmediacontrollerController')
  end

  def test_case_1
    self.expected_flow = ['> INVITE','< 200','> ACK']
    start_controller
    verify_call_flow(:out)
  end
end
