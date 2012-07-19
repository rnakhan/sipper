$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

# UAC runs on 5066
# Registrar runs on 5065
# UAS runs on 5067
# Proxy runs on 5068


class TestCallerPreference < DrivenSipTestCase
  
  # To run this test in windows, in a separate shell execute the proxy 
  # "srun -p 5068  -c caller_preference_proxy.rb"
  # and set an env var 
  # "set SIPPER_TEST_PROXY_EXTERNAL=true"
  
  def setup
    @sr = SipperConfigurator[:SessionRecord] 
    SipperConfigurator[:SessionRecord] = "msg-info"
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = [5066, 5067, 5065]

    super
    unless (RUBY_PLATFORM =~ /mswin/) || (RUBY_PLATFORM =~ /i386-mingw32/)
      system("srun -p #{SipperConfigurator[:LocalTestPort][1]+1}  -rf 3 -c #{File.join(File.dirname(__FILE__), "caller_preference_proxy.rb")} &")    
    end
    
    str2 = <<-EOF2
    
    require 'sip_test_driver_controller'
    
    module TestCallerPreference_SipInline
    
      class UasRegistrarController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][2]]
        end
        
        def on_register(session)
          logd("Received REGISTER in "+name)
          r = session.create_response(200, "OK") 
          registration_store.put(:test, session.irequest.contacts)
          session.send(r)
          session.invalidate(true)
        end
      end     
    
      class UasCallerPreferenceController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][1]]
        end
        
        def on_invite(session)
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
       
        def on_bye(session)
          session.respond_with(200)
          session.invalidate(true)
        end
        
        def order
          0
        end
        
      end
      
      class UacCallerPreferenceController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  

        def specified_transport
          [SipperConfigurator[:LocalSipperIP], 
           SipperConfigurator[:LocalTestPort][0]]
        end
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort][2])
          r = u.create_initial_request("register", "sip:sipper.com", :from=>"sip:bob@sipper.com", :to=>"sip:bob@sipper.com",
               :p_session_record=>"msg-info",
               :contact=>'sip:u1@h.example.com;audio;video;methods="INVITE BYE";q=0.2')
          r.add_contact('sip:u2@h.example.com;audio="FALSE";methods="INVITE";actor="msg-taker";q=0.2').add_contact('sip:u3@h.example.com;
          audio;actor="msg-taker";methods="INVITE";video;q=0.3').add_contact('sip:u4@h.example.com;
          audio;methods="INVITE OPTIONS";q=0.2').add_contact('sip:nasir@127.0.0.1:5067;q=0.5')
          u.send(r)
          logd("Sent a new REGISTER from "+name)
        end

        def on_success_res_for_register(session)
          session.invalidate
          u = create_udp_session()
          r = u.create_initial_request("invite", "sip:nasir@sipper.com")
          r.route = "sip:#{SipperConfigurator[:LocalSipperIP]}:#{SipperConfigurator[:LocalTestPort][1]+1};lr"
          r.to = "sip:bob@sipper.com"
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
        
        def on_success_res_for_invite(session)
          session.request_with('ACK')
          session.request_with("bye")
        end

        def on_success_res_for_bye(session)
          session.invalidate(true)
          session.flow_completed_for("TestCallerPreference")
        end
        
         
      end
    end
    EOF2
    define_controller_from(str2)
  end
  
  
  def test_rt1_controllers
    if ((RUBY_PLATFORM =~ /mswin/) || (RUBY_PLATFORM =~ /i386-mingw32/)) && !ENV['SIPPER_TEST_PROXY_EXTERNAL'] 
      return  
    end
    self.expected_flow = ["> REGISTER", "< 200"]
    start_named_controller_non_blocking("TestCallerPreference_SipInline::UacCallerPreferenceController")
    sleep 2
    verify_call_flow(:out,0)

    self.expected_flow = ["< REGISTER","> 200"]
    verify_call_flow(:in,0)

    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK", "> BYE", "< 200"]
    verify_call_flow(:out,1)

    self.expected_flow = ["< INVITE", "> 100",  "> 200", "< ACK", "< BYE", "> 200"]
    verify_call_flow(:in,1)
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = @sr
    SipperConfigurator[:LocalTestPort] = @tp
    SIP::Locator[:RegistrationStore].destroy
    super
  end

end

