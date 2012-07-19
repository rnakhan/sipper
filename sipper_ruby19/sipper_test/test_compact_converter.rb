require 'base_test_case'
require 'util/compact_converter'

class TestCompactConverter < BaseTestCase

  def test_compact_present
    assert(SipperUtil::CompactConverter.has_compact_form?("Via"))
    assert(SipperUtil::CompactConverter.has_compact_form?("via"))
    assert(SipperUtil::CompactConverter.has_compact_form?(:via))
    assert(SipperUtil::CompactConverter.has_compact_form?("call-id"))
    assert(SipperUtil::CompactConverter.has_compact_form?("Call-ID"))
    assert(SipperUtil::CompactConverter.has_compact_form?("Call-Id"))
    assert(!SipperUtil::CompactConverter.has_compact_form?("P-Non-Header"))
  end

  def test_expanded_present
    assert(SipperUtil::CompactConverter.has_expanded_form?("i"))
    assert(!SipperUtil::CompactConverter.has_expanded_form?("2"))
  end

  def test_expanded
    assert_equal("Call-ID", SipperUtil::CompactConverter.get_expanded("i"))
    assert_equal("From", SipperUtil::CompactConverter.get_expanded("f"))
    assert_nil(SipperUtil::CompactConverter.get_expanded("2"))
  end
  
  def test_compact
    assert_equal("i", SipperUtil::CompactConverter.get_compact("Call-ID"))
    assert_equal("j", SipperUtil::CompactConverter.get_compact("Reject-Contact"))
    assert_nil(SipperUtil::CompactConverter.get_compact("P-Non-Header"))
  end
      
end
