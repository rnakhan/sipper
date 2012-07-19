
require 'driven_sip_test_case'

class TestRecorderSwap < DrivenSipTestCase 

  def setup
    super
    str = <<-EOF
# FLOW : > INVITE, < 180, < 200, > ACK, < REFER, > 202, > NOTIFY, < 200, < BYE, > 200, > INVITE, < 180, < 200, > BYE, < 200
#
require 'base_controller'
module Swap
class TestCInviteController < SIP::SipTestDriverController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

  def initialize
    logd('Controller created')
  end

  def on_refer(session)
    session.respond_with(202)
    session[:carol_uri] = session.irequest.refer_to
    session.request_with('NOTIFY')
  end

  def on_bye(session)
    session.respond_with(200)
    new_session = 
      create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
    new_session.continue_recording_from session     
    new_session.request_with('INVITE', session[:carol_uri], 
      :user => 'carol', :p_session_record=>'msg-info')
    new_session[:for_carol] = true 
    session.invalidate(true)
  end

 
  def start
    session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
    session.request_with('INVITE', 'sip:nasir@sipper.com', 
      :user => 'alice', :p_session_record=>'msg-info')
  end

  def on_success_res(session)
    if session.iresponse.get_request_method == 'INVITE'
      session.request_with('ACK')
      session.request_with('BYE') if session[:for_carol]  
    elsif session.iresponse.get_request_method == 'BYE'
      session.invalidate(true)
      session.flow_completed_for('TestRecorderSwap')
    end
  end

end

class InviteReferController < SIP::BaseController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

  # change the directive below to true to start after loading.
  start_on_load false

  def initialize
    logd('Controller created')
  end

  def on_invite(session)
    session.respond_with(180)
    session.respond_with(200)
  end


  def on_success_res(session)
    session.invalidate(true) if session.iresponse.get_request_method == 'BYE'
  end

  def on_notify(session)
    session.respond_with(200)
    session.request_with('BYE')
  end

  def on_ack(session)
    r = session.create_subsequent_request('REFER')
    r.refer_to = 'sip:carol@192.168.1.2'
    session.send r
  end

  def interested?(r)
    if r[:user] && r.user == 'alice'
      return true
    else
      return false
    end
  end
end

class InviteController < SIP::BaseController 

  # change the directive below to true to enable transaction usage.
  # If you do that then make sure that your controller is also 
  # transaction aware. i.e does not try send ACK to non-2xx responses,
  # does not send 100 Trying response etc.

  transaction_usage :use_transactions=>false

  # change the directive below to true to start after loading.
  start_on_load false

  def initialize
    logd('Controller created')
  end

  def on_invite(session)
    session.respond_with(180)
    session.respond_with(200)
  end

  def on_bye(session)
    session.respond_with(200)
    session.invalidate(true)
  end

  def on_ack(session)
  end
  
  def interested?(r)
    if r[:user] && r.user == 'carol'
      return true
    else
      return false
    end
  end

end
end # module
    EOF
    define_controller_from(str)
    set_controller('Swap::TestCInviteController')
  end

  def test_case_1
    self.expected_flow = ['> INVITE','< 180','< 200','> ACK','< REFER','> 202','> NOTIFY','< 200','< BYE','> 200', '> INVITE','< 180','< 200','> ACK', '> BYE', '< 200' ]
    start_controller
    verify_call_flow(:out)
  end
end
