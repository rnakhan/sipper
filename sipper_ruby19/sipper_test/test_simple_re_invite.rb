require 'driven_sip_test_case'

# After an INVITE dialog is established, the original UAS sends a re-invite that updates
# the target. Also the peer sends a new target with the 2xx response to the re-invite.
#  
class TestSimpleReInvite < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasReInviteController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
     
        def on_invite(session)
          r = session.create_response(200)
          r.contact = '<sip:nk@sipper.com>'
          session.send(r)
        end
        
        def on_ack(session)
          r = session.create_subsequent_request("invite")
          r.contact = '<sip:nk@goblet.com>'
          session.send(r)
        end
        
        def on_success_res(session)
          session.do_record(session.remote_target)
          session.request_with('ack')
          session.invalidate(true)
        end
        
        def order
          0
        end
      end
      
      class UacReInviteController < SIP::SipTestDriverController

        transaction_usage :use_transactions=>true

        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.request_with("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          logd("Sent a new INVITE from "+name)
        end
     
        def on_success_res(session)
          session.do_record(session.remote_target)
          session.request_with('ack')   
        end
        
        def on_invite(session)
          r = session.create_response(200)
          r.contact = '<sip:alice@sipper.com>'
          session.send(r)
        end 
        
        def on_ack(session)
          session.do_record(session.remote_target)
          session.invalidate(true)
          session.flow_completed_for("TestSimpleReInvite")  
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacReInviteController")
  end
  
  
  def test_reinvite
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! sip:nk@sipper.com","> ACK", "< INVITE", "> 100", "> 200", "< ACK", "! sip:nk@goblet.com"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> INVITE", "< 100", "< 200", "! sip:alice@sipper.com", "> ACK"]
    verify_call_flow(:in)
  end
  
end

