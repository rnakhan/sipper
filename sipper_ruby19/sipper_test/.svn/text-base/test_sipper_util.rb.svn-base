$:.unshift File.join(File.dirname(__FILE__),"..","sipper")

require 'util/sipper_util'
require 'test/unit'

class TestSipperUtil < Test::Unit::TestCase
  
  def test_header_value
    assert_equal("myname", SipperUtil.header_value("My-Header: myname"))
    assert_equal("myname", SipperUtil.header_value("My-Header:   myname  "))
    assert_equal("", SipperUtil.header_value("My-Header: "))
    assert_equal("my_value", SipperUtil.header_value("my_value"))
  end
  
  def test_header_value_separate_parameters
    assert_equal("myname", SipperUtil.header_value_separate_parameters("My-Header: myname")[0])
    assert_nil(SipperUtil.header_value_separate_parameters("My-Header: myname")[1])
    assert_equal("",SipperUtil.header_value_separate_parameters("My-Header: myname;")[1])
    assert_equal("", SipperUtil.header_value_separate_parameters("My-Header: ")[0])
    assert_nil(SipperUtil.header_value_separate_parameters("My-Header ")[1])
    assert_equal("x",SipperUtil.header_value_separate_parameters("My-Header: myname;x")[1])
    assert_equal("x=1",SipperUtil.header_value_separate_parameters("My-Header: myname;x=1")[1])
    assert_equal("x=1;y=2",SipperUtil.header_value_separate_parameters("My-Header: myname;x=1;y=2")[1])
    assert_equal("x=1;y=2;z=3",SipperUtil.header_value_separate_parameters("My-Header: myname;x=1;y=2;z=3")[1])
    assert_equal("x=1;y;z=3",SipperUtil.header_value_separate_parameters("My-Header: myname;x=1;y;z=3")[1])
  end
  
  def test_parameterize_header
    assert_equal( {}, SipperUtil.parameterize_header("My-Header: myname")[1] )
    assert_equal("myname", SipperUtil.parameterize_header("My-Header: myname")[0] )
    assert_equal( {}, SipperUtil.parameterize_header("My-Header: myname;")[1] )
    assert_equal( {'x'=>""}, SipperUtil.parameterize_header("My-Header: myname;x")[1] )
    assert_equal( {'x'=>"1"}, SipperUtil.parameterize_header("My-Header: myname;x=1")[1] )
    assert_equal( {'x'=>"1", "y"=>"", "z"=>"3"}, SipperUtil.parameterize_header("My-Header: myname;x=1;y;z=3")[1] )
    assert_equal("", SipperUtil.parameterize_header(";x=1;y;z=3")[0])
  end
  
  def test_cseq_number
    assert_equal(1, SipperUtil.cseq_number("CSeq: 1 INVITE") )  
    assert_equal(23, SipperUtil.cseq_number("CSeq: 23 INVITE") )
    assert_equal(12, SipperUtil.cseq_number("12 INVITE") )
    assert_nil(SipperUtil.cseq_number("INVITE"))
  end
  
end
