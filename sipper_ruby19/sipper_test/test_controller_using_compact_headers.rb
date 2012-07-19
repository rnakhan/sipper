
require 'driven_sip_test_case'

class TestControllerUsingCompactHeaders < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasChController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false
        def on_info(session)
          logd("Received INFO in "+name)
          r = session.create_response(200, "OK")
          session.set_compact_headers([:from, :to, :call_id])
          session.send(r)
          session.invalidate
        end
        
        def order
          0
        end
      end
      
      class UacChController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        use_compact_headers [:to, :from, :call_id, :via]
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-debug")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.invalidate
          session.flow_completed_for("TestControllerUsingCompactHeaders")  
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacChController")
  end
  
  
  def test_header_order
    self.expected_flow = ["> INFO","< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INFO", "> 200"]
    verify_call_flow(:in)
    
    msg = get_out_recording.get_recording[0] # first SIP message from UAC
    ["t", "i", "v", "f"].each do |h| 
      assert(msg.index(h+": "))
    end
    
    msg = get_in_recording.get_recording[1] # second msg, i.e response from UAS
    ["t", "i", "f"].each do |h| 
      assert(msg.index(h+": "))
    end 
  end
  
end




