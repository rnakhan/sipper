require 'driven_sip_test_case'

class TestMedia < DrivenSipTestCase
  
  def setup
    @sm = SipperConfigurator[:SipperMedia] 
    SipperConfigurator[:SipperMedia] = true
    super
    str = <<-EOF
    
    require 'sip_test_driver_controller'
    require 'media/sipper_media_client'
     module SipInline
      class UacMediaController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          m = u.create_sipper_media_client
          if m.start
            m.create_media
            sleep 1
            m.send_info("127.0.0.1", 54593)
            sleep 1
            m.add_codecs
            sleep 1
            puts "sleeping..."
            m.set_status
            m.clear_codecs
          end
        end
      end      
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacMediaController")
  end
  
  def teardown
    SipperConfigurator[:SipperMedia] = @sm 
    super
  end
  
  def test_media_controllers
    start_controller
  end
  
  
end


