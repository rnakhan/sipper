require 'sip_test_case'
require 'util/expectation_parser'
require 'util/locator'
require 'generators/gen_controller'
require 'generators/gen_test'
require 'test/unit/ui/console/testrunner'

require 'fileutils'


class TestGenerated < SipTestCase

  def setup
    super 
    @orig_rp = SipperConfigurator[:DefaultRP]
    SipperConfigurator[:DefaultRP] = SipperConfigurator[:LocalTestPort]
    @orig_cp = SipperConfigurator[:ControllerPath]
    SipperConfigurator[:ControllerPath] = File.join(File.dirname(__FILE__), "tmp")
    FileUtils.mkdir SipperConfigurator[:ControllerPath]
    @orig_dir = FileUtils.pwd
    FileUtils.cd SipperConfigurator[:ControllerPath]
  end
  
  # Watch out for a minor kink in this. As we are using driven test case for the test code
  # and we are signaling the completion of test from the test code itself, we need to have 
  # the last message in the flow an incoming message for the test case. 
  def test_info
   @cflow = "< INFO, > 200"
   @tflow = "> INFO, < 200"
   _run
  end
  
  def test_invite
    @cflow = "< INVITE, > 100, > 200, < ACK, < BYE, > 200"
    @tflow = "> INVITE, < 100, < 200, > ACK, > BYE, < 200"
    _run
  end
  
  def test_sleep
    @cflow = "< INVITE, > 100, @sleep_ms 100, > 200, < ACK, < BYE, > 200"
    @tflow = "> INVITE, < 100, < 200, > ACK, > BYE, < 200"
    _run
  end
  
  def test_timer
    @cflow = "< INVITE, > 100, @set_timer 100, > 200, < ACK, < BYE, @set_timer 300, > 200"
    @tflow = "> INVITE, < 100, < 200, > ACK, @set_timer 1000, > BYE, < 200"
    _run
  end
  
  def test_wildcard
    @cflow = "< INVITE, > 180, > 212, < ACK, < BYE, > 200"
    @tflow = "> INVITE, < 1xx, < 2x2, > ACK, > BYE, < 200"
    _run
  end
  
  def test_alteration_response
    @cflow = "< INVITE, > 100, > 180, > 200, < ACK, < BYE, > 200"
    @tflow = "> INVITE, < 1xx {2,2}, < 200, > ACK, > BYE, < 200"
    _run
  end
  
  def test_alteration_request
    @cflow = "< INVITE|SUBSCRIBE,  > 200"
    @tflow = "> SUBSCRIBE, < 20x|302"
    _run
  end
  
#  def test_repetition
#    @cflow = "< INVITE, > 100, > 180, > 200, > 200, > 200,  < ACK, > INVITE, > INVITE, < 200, > ACK, < BYE, > 200"
#    @tflow = "> INVITE, < 1xx {1,2}, < 200 {3,}, > ACK, < INVITE {2,2}, > 200, < ACK, > BYE, < 200"
#    _run
#  end
  
  def _run
    SIP::Generators::GenController.new("UasController", @cflow).generate_controller(true)
    SIP::Generators::GenTest.new("TestGeneratedUas", @tflow).generate_test(true)
    load "testgenerateduas.rb"
    Test::Unit::UI::Console::TestRunner.run(Testgenerateduas)
  end
  
  def teardown
    FileUtils.cd @orig_dir
    FileUtils.rm_rf SipperConfigurator[:ControllerPath]  
    SipperConfigurator[:DefaultRP] = @orig_rp
    SipperConfigurator[:ControllerPath] = @orig_cp
  end
  
  private :_run
end