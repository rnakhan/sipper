

require 'driven_sip_test_case'

# In order to run this test properly, run a goblet enabled system 
# separately on localhost
# Then uncomment the send_post call and comment the direct respond_with 
# method. 
class TestHttpClient2 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasHttpController2 < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          #session.send_http_post_to('http://localhost:3000/config/add_new_key', 
          #  'key'=>'UnitTest1', 'desc'=>'test description', 'dtype'=>'string', 'commit'=>'submit')
          session.respond_with(200)
        end
        
        
        def on_http_res(session)
          
          res = session.create_response(200)
          res.set_body session.ihttp_response.body.split(/\r|\n\r|\n/), 'text/xml' 
          session.send res
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestHttpClient2")
        end
        
        def order
          0
        end
        
      end
      
      class UacHttpController2 < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacHttpController2")
  end
  
  
  def test_smoke_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  
end
