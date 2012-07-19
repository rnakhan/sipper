require 'base_test_case'
require 'transport/base_transport'

class TestBaseTransport < BaseTestCase
 
  def setup
    super
    require 'transport_filters'
  end
  
  def test_filters
    in_filters = Transport::BaseTransport.in_filters
    assert_equal(2, in_filters.length)
    out_filters = Transport::BaseTransport.out_filters
    assert_equal(2, out_filters.length)
    Transport::BaseTransport.in_order = ["InTransportHandler1", "InTransportHandler2"]
    in_filters = Transport::BaseTransport.in_filters
    msg = "_a__b_"
    msg = in_filters[0].do_filter(msg)
    assert_equal("1_b_", msg)
    msg = in_filters[1].do_filter(msg)
    assert_equal("12", msg)
    
    Transport::BaseTransport.out_order = ["OutTransportHandler1", "OutTransportHandler2"]
    out_filters = Transport::BaseTransport.out_filters
    msg = "_a__b_"
    msg = out_filters[0].do_filter(msg)
    assert_equal("1_b_", msg)
    msg = out_filters[1].do_filter(msg)
    assert_equal("12", msg)
  end
  
  def cleanup
    Transport::BaseTransport.clear_all_filters
  end
  
end
