require 'driven_sip_test_case'

class TestControllerUsingNict < DrivenSipTestCase

  def setup_once
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasNictController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false
        def on_info(session)
          if session['act']
            _on_info_do_success(session)
          elsif session.irequest.test_header.to_s == "1" 
            session['act'] = "yes"  # do nothing
          elsif session.irequest.test_header.to_s == "2"
            _on_info_do_provisional(session)
          end
        end
        
        def _on_info_do_success(session)
          logd("Received INFO in #{name}")
          session.local_tag = 8  #todo differentiate automatically on the same container somehow  
          r = session.create_response(200, "OK")
          session.send(r)
          session.invalidate
        end
        
        def _on_info_do_provisional(session)
          logd("Received INFO in #{name}")
          session['act'] = "yes"
          r = session.create_response(100, "Trying")
          session.send(r)
        end
        
        def order
          0
        end
        
        private :_on_info_do_success, :_on_info_do_provisional
      end
      class UacNictController1 < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_nict=>true
        transaction_timers :t1=>#{@grty*2}  # just want one retransmit
        session_timer #{@grty*8}
        
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.test_header = "1".to_s
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from #{name}")
        end
    
        
        def on_success_res(session)
          logd("Received response in #{name}")
          # session.session_timer = 200 (alternatively used the directive)
          session.invalidate
          session.flow_completed_for("TestControllerUsingNict")
        end  
      end
      
      class UacNictController2 < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false, :use_nict=>true
        transaction_timers :t1=>#{@grty*2}  # just want one retransmit
        session_timer #{@grty*8}
        
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          r.test_header = "2".to_s
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from #{name}")
        end
        
        def on_provisional(session)
          logd("Provisional received in #{self}")
        end 
        def on_success_res(session)
          logd("Received response in #{name}")
          session.invalidate
          session.flow_completed_for("TestControllerUsingNict")
        end  
      end
      
      
    end
    EOF
    define_controller_from(str)
  end
  
  
  def test_nict_succ_controllers
    self.expected_flow = ["> INFO {2,}", "< 200"]
    start_named_controller("SipInline::UacNictController1")
    verify_call_flow(:out)
    self.expected_flow = ["< INFO {2,}", "> 200"]  # one retrans
    verify_call_flow(:in)
  end
  
  def test_nict_prov_succ_controllers
    self.expected_flow = ["> INFO {1,}", "< 100", "> INFO {0,}", "< 200"]
    start_named_controller("SipInline::UacNictController2")
    verify_call_flow(:out)
    self.expected_flow = ["< INFO", "> 100", "< INFO {0,}", "> 200"]  # one retrans
    verify_call_flow(:in)
  end
  
end


