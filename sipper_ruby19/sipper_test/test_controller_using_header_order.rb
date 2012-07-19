
require 'driven_sip_test_case'

class TestControllerUsingHeaderOrder < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasHoController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>false
        def on_info(session)
          logd("Received INFO in "+name)
          session.local_tag = 6  #todo differentiate automatically on the same container somehow
          r = session.create_response(200, "OK")
          session.set_header_order([:from, :to, :via, :cseq, :call_id])
          session.send(r)
          session.invalidate
        end
        
        def order
          0
        end
      end
      
      class UacHoController < SIP::SipTestDriverController
        transaction_usage :use_transactions=>false        
        header_order [:to, :from, :call_id, :via, :cseq]
        def start
          r = Request.create_initial("info", "sip:nasir@sipper.com", :p_session_record=>"msg-debug")
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          u.send(r)
          logd("Sent a new INFO from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.invalidate
          session.flow_completed_for("TestControllerUsingHeaderOrder")  
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacHoController")
  end
  
  
  def test_header_order
    self.expected_flow = ["> INFO","< 200"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INFO", "> 200"]
    verify_call_flow(:in)
    msg = get_out_recording.get_recording[0] # first SIP message from UAC
    idx = 0
    [:to, :from, :call_id, :via, :cseq].each do |h| 
      new_idx = msg.index(SipperUtil.headerize(h.to_s)+": ")
      if new_idx
        assert(new_idx > idx) 
        idx = new_idx
      end
    end
    
    msg = get_in_recording.get_recording[1] # second msg, i.e response from UAS
    idx = 0
    [:from, :to, :via, :cseq, :call_id].each do |h| 
      new_idx = msg.index(SipperUtil.headerize(h.to_s)+": ")
      if new_idx
        assert(new_idx > idx) 
        idx = new_idx
      end
    end
    
  end
  
end



