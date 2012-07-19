$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class TestRegister < DrivenSipTestCase 
  
  def setup
    super
    SipperConfigurator[:SessionRecord]='msg-debug'
    SipperConfigurator[:WaitSecondsForTestCompletion] = 180
    str = <<-EOF
# FLOW :  < REGISTER, > 200 
#
require 'base_controller'

class TestRegisterController < SIP::SipTestDriverController 

  transaction_usage :use_transactions=>false

  def initialize
    logd('Controller created')
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
  end

  def on_register(session)
    r = session.create_response(200, "OK")
    r.contact = session.irequest.contact.uri.to_s
    session.send(r)
    session.invalidate(true)
    session.flow_completed_for('TestRegister')
  end

end
    EOF
    define_controller_from(str)
    set_controller('TestRegisterController')
  end


  def self.description
     "1.IUT is a registrant. Xlite software (version 3.0 build 29712) is used as UAC during test case development. 

    2. Sipper is a User Agent server (UAS).

    3. The variables :LocalSipperIP, :LocalSipperPort may be present in config file, if not then the values must be provided through command line
    e.g 

      srun -i 10.32.4.95 -p 5066 -t test.rb
              \           / 
               \         /
                \       / 
                IP & PORT on which Sipper is running"
  end

  def test_case_1
    self.expected_flow = ['< REGISTER','> 200']
    start_controller
    verify_call_flow(:in)
    recorded_messages = get_in_recording(0).get_recording()
    
    a = recorded_messages[0].split(SipperConfigurator[:SipperPlatformRecordingSeparator])
    assert_no_match(/sip:[A-Za-z0-9]+@/, a[0],"URI has user name")
   
    regx = Regexp.new(SipperUtil.headerize(:to))
    h = a.find {|v| v =~ regx}
    tv = SipperUtil.header_value(h)
    assert_match(/sip:[A-Za-z0-9]+@/, tv, "To URI is a sip URI")
   
    regx = Regexp.new(SipperUtil.headerize(:from))
    h = a.find {|v| v =~ regx}
    fv = SipperUtil.header_value(h)
    #remove the tag part
    fv = fv.split(";")
    assert_equal(tv, fv[0], "To URI and From URI is different")
   
   
  end
end
