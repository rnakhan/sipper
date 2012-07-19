require 'session_recorder'
require 'sipper_configurator'
require 'util/sipper_util'
require 'test/unit'

module SipperAssertions
  
  def assert_header_value_in_recording_equals(recording_row, header_name, expected, msg=nil)
    a = recording_row.split(SipperConfigurator[:SipperPlatformRecordingSeparator])
    regx = Regexp.new(SipperUtil.headerize(header_name))
    h = a.find {|v| v =~ regx}
    v = SipperUtil.header_value(h)
    assert_equal(expected, v, msg)
  end
  
  def assert_uri_in_recording_equals(recording_row, expected, msg=nil)
    a = recording_row.split(SipperConfigurator[:SipperPlatformRecordingSeparator]) 
    assert_equal(expected, a[0], msg)
  end
  
end
