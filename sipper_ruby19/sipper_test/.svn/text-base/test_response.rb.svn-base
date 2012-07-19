require 'base_test_case'

class TestResponse < BaseTestCase

  def setup
    @code = 200
    @status = "OK"
    @r = Response.create(@code, @status, :from=>"sip:nasir@codepresso.com")
  end
    
  def test_empty
    r = Response.create(@code, @status)
    assert_equal(@code, r.code)
    assert_equal(@status, r.status)
    assert(!r.incoming)
  end
  
  def test_with_header
    assert(@r.respond_to?(:from))
    assert_equal("<sip:nasir@codepresso.com>", @r.from.to_s)
    assert_equal(0, @r.content_len)
    if @r.respond_to?(:content)
      assert_nil(@r.content)
    end
    assert_nil(@r[:content])
  end
  
  def test_dynamic
    @r.via = v = "SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0;received=127.0.0.2"
    assert_equal(v, @r.via.to_s)
    pv = @r.via
    assert_equal("127.0.0.1", pv.sent_by_ip)
    assert_equal("6061", pv.sent_by_port)
    assert_nil(pv.maddr)
    pf = @r.from
    assert_equal("<sip:nasir@codepresso.com>", pf.to_s)
    assert_equal("<sip:nasir@codepresso.com>", pf.header_value)
    assert_equal({}, pf.header_params)
  end
end
