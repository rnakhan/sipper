
require 'driven_sip_test_case'

# UAC runs on 5066
# UAS runs on 5067
# Proxy runs on 5068

class TestTargetRefreshWithUpdateProxy < DrivenSipTestCase
  
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
    
    module TestTargetRefreshWithUpdateProxy_SipInline
      class UasRt6Controller < SIP::SipTestDriverController
      
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
          r = session.create_subsequent_request('update')
          orig_contact_uri = r.contact.uri
          orig_contact_uri.user = "nkhan"
          r.contact.uri = orig_contact_uri
          session.send(r)          
        end
        
        
        def on_success_res_for_update(session)
        end


        def on_bye(session)
          if session.irequest[:via].length == 1
            session.do_record("single_via")
          end
          session.do_record(session.irequest.uri.user)
          session.respond_with(200)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacRt6Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  

        pre_existing_route_set ["sip:#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]+1};lr"]

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][0]]
        end
        
        def start
          u = create_udp_session()
          r = u.create_initial_request("invite", 
              "sip:nasir@#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]}")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res_for_invite(session)
          session.request_with('ACK')
        end

        def on_update(session)
          session.respond_with(200)
          session.request_with("bye")
        end


        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestTargetRefreshWithUpdateProxy")
        end
        
         
      end
    end
    EOF2
    define_controller_from(str2)
    set_controller("TestTargetRefreshWithUpdateProxy_SipInline::UacRt6Controller")
  end
  
  
  def test_rt1_controllers
    if RUBY_PLATFORM =~ /mswin/ && !ENV['SIPPER_TEST_PROXY_EXTERNAL'] 
      return  
    end
    self.expected_flow = ["> INVITE {1,}", "< 100", "< 200", "> ACK", "< UPDATE", "> 200", "> BYE", "< 200"]
    start_controller
    sleep 3
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! double_via", "> 200", "< ACK", "> UPDATE", "< 200",  "< BYE", "! single_via", "! nkhan", "> 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = @sr
    SipperConfigurator[:LocalTestPort] = @tp
    super
  end

end

