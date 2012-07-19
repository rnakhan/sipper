require 'sip_test_case'
require 'base_controller'
require 'test_controllers/test_controller'
require 'flexmock'

class TestBaseController < SipTestCase
  include FlexMock::TestCase
  def setup
    @bc = SIP::BaseController.new
    @tc = TestController.new
    super
  end
  
  
  def test_sol
    assert( !SIP::BaseController.start_on_load? )
    assert( TestController.start_on_load? )
  end
  
  def test_name
    assert_equal("SIP::BaseController", @bc.name)
    assert_equal("TestController", @tc.name)
  end

  def test_log
    assert_nothing_raised {
      @bc.logd("Print logs")
      @bc.logi("Print logs")
      @bc.logw("Print logs")
      @bc.loge("Print logs")
      @bc.logf("Print logs")
    }
    assert_nothing_raised {
      @tc.logd("Print logs")
      @tc.logi("Print logs")
      @tc.logw("Print logs")
      @tc.loge("Print logs")
      @tc.logf("Print logs")
    }
  end
  
  def test_start
    assert !@bc.start
    ret = @tc.start
    assert(ret.nil? || ret)
  end
  
  def test_response
    r = FlexMock.new
    r.should_receive(:code).and_return(100)
    s = FlexMock.new
    s.should_receive(:iresponse).and_return(r)
    r.should_receive(:get_request_method).and_return("invite")
    @bc.extend(SipperUtil::WrapExtender)
    assert_equal("SIP::BaseController", SipperUtil::WrapExtender.last_class( @bc.on_response(s) ))
    @tc.extend(SipperUtil::WrapExtender)
    assert_equal("SIP::BaseController", SipperUtil::WrapExtender.last_class( @tc.on_response(s) )) 
    # reset mocks to return 200
    r = FlexMock.new
    r.should_receive(:code).and_return(200)
    s = FlexMock.new
    s.should_receive(:iresponse).and_return(r)
    assert_equal("TestController", SipperUtil::WrapExtender.last_class( @tc.on_response(s) )) 
  end
      
  def test_request
    r = FlexMock.new
    r.should_receive(:method).and_return("INFO")
    s = FlexMock.new
    s.should_receive(:irequest).and_return(r)
    s.should_receive(:call_id).and_return("my_call_id")
    assert(!@tc.on_request(s))
    r = FlexMock.new
    r.should_receive(:method).and_return("INVITE")
    s = FlexMock.new
    s.should_receive(:irequest).and_return(r)
    s.should_receive(:call_id).and_return("my_call_id")
    ret = @tc.on_request(s)
    assert(ret.nil? || ret)
  end
      
  def test_interested
    r = FlexMock.new
    r.should_receive(:method).and_return("INFO")
    assert(! @bc.interested?(r) )
    assert(! @tc.interested?(r) )
    r = FlexMock.new
    r.should_receive(:method).and_return("INVITE")
    assert(! @bc.interested?(r) )
    assert( @tc.interested?(r) )
  end
  
  def test_transaction_settings
    s = @tc.get_test_session
    assert(!s.use_ict)
    assert(s.use_nict)
    assert(!s.use_ist)
    assert(s.use_nist)
    s.set_transaction_timers(:Ict, :tb=>32000, :t2=>300)
  end
  
  def teardown
    super
    load 'base_controller.rb'
    load File.join('test_controllers', 'test_controller.rb')
  end
  
end


