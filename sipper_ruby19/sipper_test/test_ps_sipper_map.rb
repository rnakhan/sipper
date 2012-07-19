require 'base_test_case'
require 'util/persistence/ps_sipper_map'

class TestPsSipperMap < BaseTestCase

  def setup
    @ps = SipperUtil::Persistence::PsSipperMap.new("test_sipper_map") 
  end
  
  def test_put
    @ps.put("k1", "nasir")
    @ps.put(:k2, "khan")
    assert_equal("nasir", @ps.get("k1"))
  end
  
  def test_get
    @ps.put(:k1, "nk")
    assert_equal("nk", @ps.get(:k1))
  end
  
  def test_put_all
    h = {:a=>"1", :b=>"2", :c=>"3"}  
    @ps.put_all(h)
    assert_equal(3, @ps.get_all_keys.length)
  end
  
  def test_put_all_twice
    h = {:a=>"1", :b=>"2", :c=>"3"}  
    @ps.put_all(h)
    h = {:d=>"1", :e=>"2", :f=>"3"}
    @ps.put_all(h)
    assert_equal(6, @ps.get_all_keys.length)
  end
  
  def test_delete
    @ps.put(:k1, "nk")
    @ps.delete(:k1)
    assert_nil(@ps.get(:k1))
  end
  
  def test_delete_deleted
    @ps.put(:k1, "nk")
    @ps.delete(:k1)
    assert_nothing_raised {@ps.delete(:k1)}
  end
  
  def test_destroy
    @ps.destroy
    @ps.put(:k1, "nk")
    assert_equal("nk", @ps.get(:k1))
  end
  
  def teardown
    @ps.destroy
  end
end