
# This test is a kludge to test the remote target update for UAs. The B2BUA here is 
# basically a Proxy on steroids. The Call-Id and from/to tag mangling is done as everything
# is running on the same box and so session mismatch could happen otherwise.
# The take away from this test is that ACK is sent directly to UAS. 

require 'driven_sip_test_case'
require 'sdp/sdp_generator'

class TestRemoteTargetUpdateOn2xx < DrivenSipTestCase

  def self.description
    "In this test we are running the B2BUA as a stateless proxy that doesnt record route, "+
    "we are copying the Contacts from the two end UAs to peer sessions and thereby testing  "+
    "the updation of remote target dynamically in session based on refreshed target"
  end
  
  def setup
    SipperConfigurator[:ControllerPath] = nil
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [5066, 5079, 5080]
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    require 'b2bua_controller'
    
    module SipKludge
      class UasB2buaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 5080]
        end
        
        def on_invite(session)
          session.name = "uas"
          r = session.create_response(200)
          r.sdp = SDP::SdpGenerator.make_no_media_sdp
          session.send(r)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestRemoteTargetUpdateOn2xx")
        end
        
        
        def order
          1
        end
        
       
      end
      
      
      class TestB2buaController < SIP::B2buaController
      
        transaction_usage :use_transactions=>false
        t2xx_usage false
        
        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 5079]
        end
        
        def on_invite(session)
          session.name = "b2buas"
          peer = get_or_create_peer_session(session, SipperConfigurator[:LocalSipperIP], 5080)
          peer.name = "b2buac"
          r = create_b2bua_request(session)
          r.contact = session.irequest.contact
          r.call_id = session.irequest.call_id.to_s + "1"
          r.from = session.irequest.from
          r.to = session.irequest.contact
          r.p_session_record = nil
          peer.send r
        end


        def on_success_res(session)
          r = create_b2bua_response(session)
          peer = get_peer_session(session)
          r.contact = session.iresponse.contact
          peer.send r
          invalidate_sessions(session, true)
        end
        
      end
      
      
      class UacB2buaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 5066]
        end
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], 5079)
          u.name = "uac"
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          ack = session.create_2xx_ack
          ack.call_id = ack.call_id.to_s + "1"
          session.send ack
          session.invalidate(true)
        end
        
       
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipKludge::UacB2buaController")
  end
  
  
  def test_b2bua
    self.expected_flow = ["> INVITE", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE",  "> 200"] # this is b2bua recording
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:LocalTestPort] = @tp
    super
  end
  
end
