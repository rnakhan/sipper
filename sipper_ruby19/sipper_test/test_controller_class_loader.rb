
require 'base_test_case'


class TestControllerClassLoader < BaseTestCase
  include SIP
  def setup
    @path = File.join(File.dirname(__FILE__), "test_controllers", "class_loading")
  end
  
  def test_empty_clear
    assert_nothing_raised {ControllerClassLoader.clear_all}
  end
  
  def test_empty_controllers
    assert_equal([], ControllerClassLoader.controllers)
    test_empty_clear
    assert_equal([], ControllerClassLoader.controllers)
  end
  
  def test_load
    file = File.join(@path,"ordered", "first_ordered_controller.rb")
    ControllerClassLoader.load file
    assert_equal("FirstOrderedController", ControllerClassLoader.controllers[0].to_s)  
    file = File.join(@path,"ordered", "second_ordered_controller.rb")
    ControllerClassLoader.load file
    assert_equal(2, ControllerClassLoader.controllers.size)
    assert_not_nil(ControllerClassLoader.controllers.find {|x| x.to_s == "SecondOrderedModule::SecondOrderedController"} )
    ControllerClassLoader.load file  #load again
    assert_equal(2, ControllerClassLoader.controllers.size)
  end
 
   def teardown
     ControllerClassLoader.clear_all
   end
   
end
