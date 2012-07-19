require 'base_test_case'

class TestRequest < BaseTestCase

  def setup
    @method = "invite"
    @uri = "sip:nasir@sipper.com"
    @r = Request.create_initial(@method, @uri, :p_asserted_identity => "sip:nina@home.com")                        
  end
  
  def test_empty_request
    r = Request.create_initial(@method, @uri)
    assert_equal(r.method, @method.upcase)
    assert_equal(r.uri, @uri)
    Request.sys_hdrs.each do |hdr|
      assert_respond_to r, hdr
    end
  end
  
  def test_with_header
    assert_respond_to @r, :p_asserted_identity
  end

  def test_dynamic_methods
    assert_not_nil @r.p_asserted_identity
    @r.add_p_asserted_identity @uri
    assert_equal  "<"+@uri+">", @r.p_asserted_identitys[1].to_s
    @r.p_asserted_identity = @uri
    assert_equal  "<"+@uri+">", @r.p_asserted_identity.to_s
  end
  
  def test_add_headers
    h = {:a=>"1", :b=>"2"}
    @r.define_from_hash h
    assert_equal "1", @r.a.to_s
    assert_equal "2", @r.b.to_s
    test_dynamic_methods
  end 

  def test_add_header
    assert_raise(NoMethodError){ @r.a }
    @r.a = "hello"
    assert_equal("hello", @r.a.to_s)
    @r.add_a "bye"
    assert_equal("bye", @r.as[1].to_s)
  end
  
  def test_mv_header
    @r.a = "hello,bye"
    assert_equal("hello", @r.a.to_s)
    @r.add_a  "hello_again"
    assert_equal("bye", @r.as[1].to_s)
    assert_equal("hello_again", @r.as[2].to_s)
  end
  
  def test_mv_arr_header
    @r.a = ["hello", "bye"]
    assert_equal("hello", @r.as[0].to_s)
    assert_equal("bye", @r.as[1].to_s)
  end
  
  def test_mv_formatting
    @r.allow = arr = ["INVITE", "BYE", "ACK"]
    msg_str = @r.to_s
    assert(msg_str.index("Allow: INVITE, BYE, ACK"))
    # now multiline
    @r.format_as_separate_headers_for_mv(:allow)
    msg_str = @r.to_s
    arr.each do |m|
      rx = Regexp.new("Allow: #{m}")
      assert(msg_str =~ rx)
    end
  end
    
  def test_compact_formatting1
    @r.compact_headers = [:via, :to]
    @r.via = "SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0"
    @r.from = "sipper <sip:sipper@127.0.0.1:6061>;tag=1"
    @r.to = "sut <sip:service@127.0.0.1:5060>"
    msg_str = @r.to_s
    assert(msg_str.index("v: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0"))
    assert(msg_str.index("From: sipper <sip:sipper@127.0.0.1:6061>;tag=1"))
    assert(msg_str.index("t: sut <sip:service@127.0.0.1:5060>"))
  end
  
  def test_compact_formatting2
    @r.compact_headers = [:all_headers]
    @r.via = "SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0"
    @r.from = "sipper <sip:sipper@127.0.0.1:6061>;tag=1"
    @r.to = "sut <sip:service@127.0.0.1:5060>"
    @r.p_test = "Test"
    msg_str = @r.to_s
    assert(msg_str.index("v: SIP/2.0/UDP 127.0.0.1:6061;branch=z9hG4bK-2352-1-0"))
    assert(msg_str.index("f: sipper <sip:sipper@127.0.0.1:6061>;tag=1"))
    assert(msg_str.index("t: sut <sip:service@127.0.0.1:5060>"))
    assert(msg_str.index("P-Test: Test"))
  end
    
  def test_content_len
    assert_equal(0, @r.content_len)
    @r.content = File.new(File.join(File.dirname(__FILE__), "c_134.txt")).readlines
    assert_equal(141, @r.content_len)
  end
    
  
end
