
require 'driven_sip_test_case'


require 'transport/base_transport'


class TestRemotePortUpdateOnResponse < DrivenSipTestCase

  def setup
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [5066, 5067]
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasRpuController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.make_new_offer
          r = session.create_response(200)
          r.contact.uri.port = 5067
          session.send(r)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestRemotePortUpdateOnResponse")
        end
        
        def order
          0
        end
        
      end
      
      class UacRpuController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          #u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort][0])
          u = create_udp_session
          r = u.create_initial_request("invite", "sip:nasir@" + SipperConfigurator[:LocalSipperIP]+":"+SipperConfigurator[:LocalTestPort][0].to_s, :p_session_record=>"msg-info")
          u.offer_answer.make_new_offer
          #r.sdp = SDP::SdpGenerator.make_no_media_sdp
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
          session.do_record(session.rp.to_s)
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacRpuController")
  end
  
  
  def test_rpu_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "! 5067", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:LocalTestPort] = @tp
    super
  end

  
end
