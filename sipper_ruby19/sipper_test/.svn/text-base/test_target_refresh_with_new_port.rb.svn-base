
require 'driven_sip_test_case'


class TestTargetRefreshWithNewPort < DrivenSipTestCase
  
  # To run this test in windows, in a separate shell execute the proxy 
  # "srun -p 5070 -o 5068 -c nonrr_proxy.rb"
  # and set an env var 
  # "set SIPPER_TEST_PROXY_EXTERNAL=true"
  # You would do similar thing for rr_proxy with a higher port in a second shell
  # "srun -p 5071 -o 5068 -c rr_proxy.rb"
  # Let these two proxies run.
  # Then run the test cases, after you are done make sure to unset the env var by
  # "set SIPPER_TEST_PROXY_EXTERNAL="
  # For one run you need only to execute the two proxies only once for all tests. 
  def setup
    @sr = SipperConfigurator[:SessionRecord] 
    SipperConfigurator[:SessionRecord] = "msg-info"
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [7067, 7068, 7069]

    super
    unless RUBY_PLATFORM =~ /mswin/
      system("srun -p #{SipperConfigurator[:LocalTestPort][2]+1} -o #{SipperConfigurator[:LocalTestPort][1]} -rf 3 -c #{File.join(File.dirname(__FILE__), "nonrr_proxy.rb")} &")    
    end
    
    str2 = <<-EOF2
    
    require 'stray_message_manager'

    class ByeStrayHandler < SIP::StrayMessageHandler
      def handle(m)
        [SIP::StrayMessageHandler::SMH_TREAT_INITIAL, m]
      end
    end
    
    require 'sip_test_driver_controller'
    
    module TestTargetRefreshWithNewPort_SipInline
      class UasRt61Controller < SIP::SipTestDriverController
      
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
          orig_contact_uri.port = SipperConfigurator[:LocalTestPort][2]
          r.contact.uri = orig_contact_uri
          session.send(r)          
        end
        
        
        def on_success_res_for_update(session)
          session.invalidate(true)
        end
      end
      
      
      class UasRt62Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][2]]
        end
   
        def on_bye(session)
          if session.irequest[:via].length == 1
            session.do_record("single_via")
          end
          session.do_record(session.irequest.uri.user)
          session.respond_with(200)
          session.invalidate(true)
        end
        
      end
      
      class UacRt6Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  

        pre_existing_route_set ["sip:#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][2]+1};lr"]

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
          session.flow_completed_for("TestTargetRefreshWithNewPort")
        end
        
         
      end
    end
    EOF2
    define_controller_from(str2)
    set_controller("TestTargetRefreshWithNewPort_SipInline::UacRt6Controller")
  end
  
  
  def test_rtup_controllers
    if RUBY_PLATFORM =~ /mswin/ && !ENV['SIPPER_TEST_PROXY_EXTERNAL'] 
      return  
    end
    self.expected_flow = ["> INVITE {1,}", "< 100", "< 200", "> ACK", "< UPDATE", "> 200", "> BYE {1,2}", "< 200 {1,2}"]
    start_controller
    sleep 3
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! double_via", "> 200", "< ACK", "> UPDATE", "< 200"]
    verify_call_flow(:in)
    self.expected_flow = ["< BYE {1,2}", "! single_via {1,2}", "! nkhan {1,2}", "> 200 {1,2}"]
    verify_call_flow(:in, 1)
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = @sr
    SipperConfigurator[:LocalTestPort] = @tp
    SIP::StrayMessageManager.clear_handler
    super
  end

end
