
require 'driven_sip_test_case'


class TestHttpOnly < DrivenSipTestCase

  def setup
    @http_server = SipperConfigurator[:SipperHttpServer]
    @sr = SipperConfigurator[:SessionRecord] 
    SipperConfigurator[:SessionRecord] = "msg-info"
    SipperConfigurator[:SipperHttpServer] = true
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UacHttpOnlyController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
       
        def start
          session = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          session.send_http_get_to('http://127.0.0.1:2000/get')
          session.do_record("GET_SENT")
          logd("Sent a new GET from "+name)
        end
        
        
        def on_http_res(session)
            logd("Received a 200 OK for GET sent from "+name)
            session.do_record("200_FOR_GET_RECVD")
            session.invalidate(true)
            session.flow_completed_for("TestHttpOnly")
        end
          
       def order
          0
        end
        
      end
      
      
      
      class UasHttpOnlyController < SIP::SipTestDriverController
     
        def on_http_get(req, res, session)
          res.body = <<-HTTP_RES
           <HTML> <h1>Please enter your info.</h2>
             <form name="input" action="send_data"
                method="post">
             Username: 
               <input type="text" name="user">
               <input type="submit" value="Submit">
            </form>
          </HTML>
          HTTP_RES
          res['Content-Type'] = "text/html"
        end
         
         
      end #class
    end  # module
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacHttpOnlyController")
  end
  
  
  def test_http_controllers
    self.expected_flow = ["! GET_SENT", "! 200_FOR_GET_RECVD"]
    start_controller
    verify_call_flow(:neutral)
  end

  def teardown
    super
    SipperConfigurator[:SipperHttpServer] = @http_server
    SipperConfigurator[:SessionRecord] = @sr
  end
end
