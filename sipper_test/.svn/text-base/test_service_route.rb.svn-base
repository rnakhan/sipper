require 'driven_sip_test_case'
require 'proxy_controller'

#Msg sequence for REGISTER
# UA1 -------REGISTRAR
#Msg sequence for INVITE
# UA1 -----P1-----UA2

# UAC runs on 5066
# UAS runs on 5067
# Proxy runs on 5069
#Registrar runs on 5070

  # To run this test in windows, in a separate shell execute the proxy 
  # "srun -p 5069 -o 5067 -c path_r_proxy.rb"
  # and set an env var 
  # "set SIPPER_TEST_PROXY_EXTERNAL=true"
  # Do similar thing for registrar with a higher port in a second shell
  # "srun -p 5070  -c registrar_proxy.rb"
  # Let these two proxies run.
  # Then run the test cases, after you are done make sure to unset the env var by
  # "set SIPPER_TEST_PROXY_EXTERNAL="
  # For one run you need only to execute the two proxies only once for all tests.
class TestServiceRoute1 < DrivenSipTestCase
  
  
  def setup
    @sr = SipperConfigurator[:SessionRecord] 
    SipperConfigurator[:SessionRecord] = "msg-info"
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [5066, 5067]
        
    super
    unless RUBY_PLATFORM =~ /mswin/
      system("srun -p #{SipperConfigurator[:LocalTestPort][1]+2} -o #{SipperConfigurator[:LocalTestPort][1]+3} -rf 6 -c #{File.join(File.dirname(__FILE__), "path_r_proxy.rb")} &")    
      system("srun -p #{SipperConfigurator[:LocalTestPort][1]+3} -rf 6 -c #{File.join(File.dirname(__FILE__), "registrar_proxy.rb")} &")    
    end
    
    str2 = <<-EOF2
    
    require 'sip_test_driver_controller'
    require 'proxy_controller'
    
    module SipInline
    
      class UA2ServiceRoute1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false  

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][1]]
        end
        
        def on_invite(session)
           if session.irequest[:via].length == 2
            session.do_record("double_via")
          end
          session.respond_with(200)
        end

        def on_ack(session)
          session.request_with('BYE')
        end  
        
        def on_success_res_for_bye(session)
          session.invalidate(true)  
          session.flow_completed_for("TestServiceRoute1")          
        end
        
      def order
        0
      end  
        
      end    
    
           
      class UA1ServiceRoute1Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false  

        #pre_existing_route_set ["sip:#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]+2};lr"]

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][0]]
        end
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort][1]+3)
          r = u.create_initial_request("register", "sip:sipper.com", 
               :from=>"sip:bob@sipper.com", :to=>"sip:bob@sipper.com",
               :expires=>"400",
               :p_session_record=>"msg-info")
          u.send(r)
          logd("Sent a new REGISTER from #{name}")
        end
     
        def on_success_res_for_register(session)
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort][1])
          r = u.create_initial_request("invite","sip:nasir@#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]}")
          r.to = "sip:bob@sipper.com"
          r.route = session.iresponse.service_route
          u.send(r)
          session.invalidate(true)              
        end
        
        def on_success_res_for_invite(session)
          session.request_with('ACK')
        end  
        
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
            
      end
    end
    EOF2
    define_controller_from(str2)
    set_controller("SipInline::UA1ServiceRoute1Controller")
  end
  
  
  def test_service_route1_controllers
    if RUBY_PLATFORM =~ /mswin/ && !ENV['SIPPER_TEST_PROXY_EXTERNAL'] 
      return  
    end
    
    self.expected_flow = ["> REGISTER", "< 100 {0,}", "< 200"]
    sleep 2
    start_controller
    verify_call_flow(:out,0)
    self.expected_flow = ["> INVITE", "< 100 {0,}","< 200","> ACK", "< BYE","> 200"]
    verify_call_flow(:out,1)
    self.expected_flow = ["< INVITE","! double_via", "> 100 {0,}","> 200","< ACK", "> BYE","< 200"]
    verify_call_flow(:in)
    sleep 5    
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = @sr
    SipperConfigurator[:LocalTestPort] = @tp
    
    super
  end

end

