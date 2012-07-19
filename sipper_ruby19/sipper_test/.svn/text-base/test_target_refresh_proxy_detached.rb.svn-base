
require 'driven_sip_test_case'

# UAC runs on 5066
# UAS runs on 5067
# Proxy runs on 5068

class TestTargetRefreshProxyDetached < DrivenSipTestCase
  
  
  # To run this test in windows, in a separate shell execute the proxy 
  # "srun -p 5068 -0 5067 -c nonrr_proxy.rb"
  # and set an env var 
  # "set SIPPER_TEST_PROXY_EXTERNAL=true"
  # You would do similar thing for rr_proxy with a higher port in a second shell
  # "srun -p 5069 -0 5067 -c rr_proxy.rb"
  # Let these two proxies run.
  # Then run the test cases, after you are done make sure to unset the env var by
  # "set SIPPER_TEST_PROXY_EXTERNAL="
  # For one run you need only to execute the two proxies only once for all tests. 
  def setup
    @sr = SipperConfigurator[:SessionRecord] 
    SipperConfigurator[:SessionRecord] = "msg-info"
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [5066, 5067]

    super
    unless RUBY_PLATFORM =~ /mswin/
      system("srun -p #{SipperConfigurator[:LocalTestPort][1]+1} -o #{SipperConfigurator[:LocalTestPort][1]} -rf 3 -c #{File.join(File.dirname(__FILE__), "nonrr_proxy.rb")} &")    
    end
    
    str2 = <<-EOF2
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasRt3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][1]]
        end
        
        def on_invite(session)
          if session.irequest[:via].length == 2
            session.do_record("double_via")
          end
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestTargetRefreshProxyDetached")
        end
        
        def order
          0
        end
        
      end
      
      class UacRt3Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  

        pre_existing_route_set ["sip:#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]+1};lr"]

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][0]]
        end
        
        def start
          u = create_session()
          r = u.create_initial_request("invite", 
              "sip:nasir@#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]}", :to=>"Nasir Khan <sip:nasir@sipper.com>")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          if session.irequest[:via].length == 1
            session.do_record("single_via")
          end
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF2
    define_controller_from(str2)
    set_controller("SipInline::UacRt3Controller")
  end
  
  
  def test_rt1_controllers
    if RUBY_PLATFORM =~ /mswin/ && !ENV['SIPPER_TEST_PROXY_EXTERNAL'] 
      return  
    end
    self.expected_flow = ["> INVITE {1,}", "< 100", "< 200", "> ACK", "< BYE","! single_via", "> 200"]
    start_controller
    sleep 3
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! double_via", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = @sr
    SipperConfigurator[:LocalTestPort] = @tp
    super
  end

end

