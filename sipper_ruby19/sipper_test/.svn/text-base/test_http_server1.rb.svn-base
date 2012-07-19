

require 'driven_sip_test_case'


class TestHttpServer1 < DrivenSipTestCase

  def setup
    @http_server = SipperConfigurator[:SipperHttpServer]
    SipperConfigurator[:SipperHttpServer] = true
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasHttp1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          session.send_http_get_to('http://127.0.0.1:2000/get')  
        end
        
        
        def on_http_res(session)
          res = session.create_response(200)
          res.set_body session.ihttp_response.body.split(/\r|\n\r|\n/), 'text/xml' 
          session.send res
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestHttpServer1")
        end
        
        def order
          0
        end
        
      end
      
      class UacHttp1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          r = Request.create_initial("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        def on_http_get(req, res, session)
          res.body = "<HTML>Sending some HTML data back</HTML>"
          res['Content-Type'] = "text/html"
        end
        
        def on_success_res(session)
          f = session.iresponse.body =~ /HTML/
          if f
           rec = true
          else
           rec = false
          end
          session.do_record(rec)
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
    set_controller("SipInline::UacHttp1Controller")
  end
  
  
  def test_http_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "! true", "> ACK", "< BYE", "> 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end

  def teardown
    super
    SipperConfigurator[:SipperHttpServer] = @http_server
  end
end
