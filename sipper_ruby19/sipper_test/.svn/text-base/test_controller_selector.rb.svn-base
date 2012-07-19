require 'base_test_case'


class TestControllerSelector < BaseTestCase
 

  def setup
    @path = File.join(File.dirname(__FILE__), "test_controllers", "class_loading")
  end

  def test_ordered_load_with_dir
    p = File.join(@path, "ordered")
    c = SIP::ControllerSelector.new( Dir.new(p) )
    assert_equal("SecondOrderedModule::SecondOrderedController", c.get_controllers[0].name)
    assert_equal("FirstOrderedController", c.get_controllers[1].name)
    assert_equal("SecondOrderedModule::RecondOrderedController", c.get_controllers[2].name)
  end
  
  def test_ordered_load_with_path
    p = File.join(@path, "ordered")
    c = SIP::ControllerSelector.new( p )
    assert_equal("SecondOrderedModule::SecondOrderedController", c.get_controllers[0].name)
    assert_equal("FirstOrderedController", c.get_controllers[1].name)
    assert_equal("SecondOrderedModule::RecondOrderedController", c.get_controllers[2].name)
    assert_equal("FirstOrderedController", c.get_controller("FirstOrderedController").name)
  end
  
  
  def test_unordered_load
    p = File.join(@path, "unordered")
    c = SIP::ControllerSelector.new( Dir.new(p) )
    assert_not_nil(c.get_controllers.find {|x| x.name == "SecondUnorderedModule::SecondUnorderedController"})
    assert_not_nil(c.get_controllers.find {|x| x.name == "FirstUnorderedController"})
  end
  
  def test_clear
    p = File.join(@path, "ordered")
    c = SIP::ControllerSelector.new( p )
    assert_equal(3, c.get_controllers.size)
    c.clear_all
    assert_equal(0, c.get_controllers.size)
  end
  
  
  def teardown
    if @cs
      @cs.clear_all 
    else   
      SIP::ControllerClassLoader.clear_all
    end
  end
    
end
