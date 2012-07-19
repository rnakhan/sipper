
require 'base_test_case'
require 'session_state/dialog_routes'
require 'request'
require 'response'

class TestDialogRoutes < BaseTestCase
  
  def setup
    super
    #
  end
  
  def test_null_dr
    dr = DialogRoutes.new
    assert_nil(dr.get_ruri_and_routes[0])
    assert(dr.get_ruri_and_routes[1].empty?)
  end
  
  
  def test_pre_existing
    routes = ["<sip:sipper.com;lr>", "<sips:goblet.com;lr>"]
    dr = DialogRoutes.new(routes)
    assert_nil(dr.get_ruri_and_routes[0])
    assert_equal(routes, dr.get_ruri_and_routes[1].map {|x| x.to_s})
  end
  
  def test_request_without_rr
    dr = DialogRoutes.new
    r = Request.create_initial("invite", "sip:nasir@sipper.com", :contact=>"sip:nasir@goblet.com")
    dr.request_received(r)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[0].to_s)
    assert(dr.get_ruri_and_routes[1].empty?)
  end
  
  # The route set MUST be set to the list of URIs in the Record-Route header field from the
  #  request, taken in order and preserving all URI parameters.  If no Record-Route header 
  #  field is present in the request, the route set MUST be set to the empty set.  
  #  This route set, even if empty, overrides any pre-existing route set for future 
  #  requests in this dialog.  The remote target MUST be set to the URI from the Contact 
  #  header field of the request.
  def test_request_without_rr_override_plrs
    routes = ["<sip:sipper.com;lr>", "<sips:goblet.com;lr>"]
    dr = DialogRoutes.new(routes)
    r = Request.create_initial("invite", "sip:nasir@sipper.com", :contact=>"sip:nasir@goblet.com")
    dr.request_received(r)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[0].to_s)
    assert(dr.get_ruri_and_routes[1].empty?)
  end
  
  def test_request_with_rr
    dr = DialogRoutes.new
    r = Request.create_initial("invite", "sip:nasir@sipper.com", :contact=>"sip:nasir@goblet.com", 
        :record_route=>"<sip:example1.com;lr>,<sip:example2.com;lr>")
    dr.request_received(r)
    assert_equal("<sip:example1.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("<sip:example2.com;lr>", dr.get_ruri_and_routes[1][1].to_s)
  end
  
  def test_request_with_rr_override_plrs
    routes = ["<sip:sipper.com;lr>", "<sips:goblet.com;lr>"]
    dr = DialogRoutes.new(routes)
    assert_equal("<sip:sipper.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("<sips:goblet.com;lr>", dr.get_ruri_and_routes[1][1].to_s)
    r = Request.create_initial("subscribe", "sip:nasir@sipper.com", :contact=>"sip:nasir@goblet.com", 
        :record_route=>"<sip:example1.com;lr>,<sip:example2.com;lr>")
    dr.request_received(r)
    assert_equal("<sip:example1.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("<sip:example2.com;lr>", dr.get_ruri_and_routes[1][1].to_s)
  end
  
  
  def test_request_without_rr_subsequent_with_rr
    dr = DialogRoutes.new
    r = Request.create_initial("invite", "sip:nasir@sipper.com", :contact=>"sip:nasir@goblet.com")
    dr.request_received(r)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[0].to_s)
    assert(dr.get_ruri_and_routes[1].empty?)
    r = Request.create_initial("subscribe", "sip:nasir@sipper.com", :contact=>"sip:nasir@sipper.com", 
        :record_route=>"sip:example1.com;lr,sip:example2.com;lr")
    dr.request_received(r)
    assert_equal("sip:nasir@sipper.com", dr.get_ruri_and_routes[0].to_s)
    assert(dr.get_ruri_and_routes[1].empty?)
  end
  
  def test_response_with_rr
    dr = DialogRoutes.new
    r = Response.create(200, "OK", :contact=>"sip:nasir@goblet.com", 
        :record_route=>"<sip:example1.com;lr>,<sip:example2.com;lr>", :cseq=>"1 NOTIFY")
    dr.response_received(r)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[0].to_s)
    assert_equal("<sip:example2.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("<sip:example1.com;lr>", dr.get_ruri_and_routes[1][1].to_s)
  end
  
  def test_response_with_rr_subsequent_with_rr
    dr = DialogRoutes.new
    r = Response.create(200, "OK", :contact=>"sip:nasir@goblet.com", 
        :record_route=>"<sip:example1.com;lr>,<sip:example2.com;lr>", :cseq=>"1 NOTIFY")
    dr.response_received(r)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[0].to_s)
    assert_equal("<sip:example2.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("<sip:example1.com;lr>", dr.get_ruri_and_routes[1][1].to_s)
    r = Response.create(200, "OK", :contact=>"sip:nasir@sipper.com", 
        :record_route=>"<sip:example3.com;lr>,<sip:example4.com;lr>", :cseq=>"1 INVITE")
    dr.response_received(r)
    assert_equal("sip:nasir@sipper.com", dr.get_ruri_and_routes[0].to_s)
    assert_equal("<sip:example2.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("<sip:example1.com;lr>", dr.get_ruri_and_routes[1][1].to_s)
  end
  
  
  def test_rr_without_lr
    dr = DialogRoutes.new
    r = Request.create_initial("invite", "sip:nasir@sipper.com", :contact=>"sip:nasir@goblet.com", 
        :record_route=>"<sip:example1.com>,<sip:example2.com;lr>")
    dr.request_received(r)
    assert_equal("sip:example1.com", dr.get_ruri_and_routes[0].to_s)
    assert_equal("<sip:example2.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[1][1].to_s)
  end
  
  
  def test_response_rr_without_lr
    dr = DialogRoutes.new
    r = Response.create(200, "OK", :contact=>"sip:nasir@goblet.com", 
        :record_route=>"<sip:example1.com;lr>,<sip:example2.com>", :cseq=>"1 NOTIFY")
    dr.response_received(r)
    assert_equal("sip:example2.com", dr.get_ruri_and_routes[0].to_s)
    assert_equal("<sip:example1.com;lr>", dr.get_ruri_and_routes[1][0].to_s)
    assert_equal("sip:nasir@goblet.com", dr.get_ruri_and_routes[1][1].to_s)
  end
  
  def teardown
    #
    super
  end
  
end
