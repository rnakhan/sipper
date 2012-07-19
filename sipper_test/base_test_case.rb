$:.unshift File.join(File.dirname(__FILE__),"..","sipper")

require 'sipper'

$:.unshift File.join(File.dirname(__FILE__),"..", "sipper","lib")
$:.unshift File.join(File.dirname(__FILE__),"..","sipper","lib", "smc")

require 'sipper_assertions'

require 'yaml'
require 'session_recorder'

require 'test/unit'

class BaseTestCase < Test::Unit::TestCase
 
  def setup
    SipperConfigurator[:SessionRecordPath] = File.join(SipperConfigurator[:LogPath], ".Test#{self.class.name.split('::')[-1]}")
    FileUtils.mkdir_p SipperConfigurator[:SessionRecordPath]
    #puts "Now testing #{self.class.name}"
  end
  
  def teardown
    FileUtils.rm_r SipperConfigurator[:SessionRecordPath]  unless (Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*"))).length>0 if File.exist?(SipperConfigurator[:SessionRecordPath]) if SipperConfigurator[:SessionRecordPath]
  end
  
  undef_method :default_test   

end
