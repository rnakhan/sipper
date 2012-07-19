require 'request'
require 'response'
require 'sipper_configurator'
require 'util/sipper_util'
require 'sip_headers/header'

# Maintains the route set and remote target for the dialog, also encapsulating the reason for 
# target refresh and strict router manipulation. 

class DialogRoutes

  LRREGX = /;lr/.freeze
  
  def initialize(pre_existing=nil)
     prex = pre_existing || SipperConfigurator[:PreExistingRouteSet]
     if prex
       prex.each do |rt|
         raise ArgumentError, "Only loose routes can be preloaded routes" unless rt.to_s =~ LRREGX    
       end
     end
    _assign_route_set(prex || [])
    @remote_target = nil
    @route_learned = false
    @target_refreshed = false
  end
  
  def _assign_route_set(rarr)
    @route_set = rarr.map do |r|
      unless r.class ==  SipHeaders::Route
        SipHeaders::Route.new.assign(r.to_s)
      else
        r
      end
    end
  end
  
  def request_received(request)
    if SipperConfigurator[:TargetRefreshMethods].include? request.method
      _update_rt(request)
    end
    return if @route_learned
    if SipperConfigurator[:DialogCreatingMethods].include? request.method
      if request[:record_route]
        _assign_route_set(request.record_routes) 
      else
        _assign_route_set([])
      end
      @route_learned = true
    end
  end
  
  
  def response_received(response)
    if SipperConfigurator[:TargetRefreshMethods].include?(response.get_request_method)  && response.code != 100
      _update_rt(response)
    end
    return if @route_learned
    if SipperConfigurator[:DialogCreatingMethods].include? response.get_request_method
      if response[:record_route]
        _assign_route_set(response.record_routes.reverse)  
      else
        _assign_route_set([])
      end
      @route_learned = true if response.code >= 200
    end
  end
  

  
  # Returns the Request URI and route header values. [remote_target, [routes]], if there is no
  # route set then an empty array for routes is returned. 
  # e.g. [remote_target, [], bool]
  # The last element of the array is a boolean use_ruri which is true of the request uri should
  # be used to determine the destination of the request, otherwise top route header should be 
  # used. 
  # 
  # RFC 3261 12.2.1.1
  # The UAC uses the remote target and route set to build the Request-URI and Route header field 
  # of the request. 
  # 
  # If the route set is empty, the UAC MUST place the remote target URI into the 
  # Request-URI.  The UAC MUST NOT add a Route header field to the request.
  # 
  # If the route set is not empty, and the first URI in the route set contains the lr parameter 
  # (see Section 19.1.1), the UAC MUST place the remote target URI into the Request-URI and MUST 
  # include a Route header field containing the route set values in order, including all parameters.
  # 
  # If the route set is not empty, and its first URI does not contain the lr parameter, the UAC MUST 
  # place the first URI from the route set into the Request-URI, stripping any parameters that are 
  # not allowed in a Request-URI.  The UAC MUST add a Route header field containing the remainder 
  # of the route set values in order, including all parameters.  
  # The UAC MUST then place the remote target URI into the Route header field as the last value.
  # todo - see what needs to be stripped while placing top route in ruri
  def get_ruri_and_routes
    _find_targets(@remote_target, @route_set) 
  end
  
  # This will typically be used for initial request only when the controller changes the 
  # route headers or pushes new route headers. Here we completely ignore the @route_set and
  # just go by the route headers. Note that the pre_existing route headers would already
  # have been added to the request when the request was first created. 
  def get_ruri_and_routes_for_pushed_routes(request)
    if rs=request[:route]
      return _find_targets(@remote_target, rs)
    else
      return get_ruri_and_routes
    end
  end
  
  def _find_targets(rt, rs)
    if rs.empty?
      [rt, [], true]
    else
      if rs[0].uri.has_param?(:lr)  
        [rt, rs, false]  
      else
        [rs[0].uri, rs[1..-1]+[rt], true]
      end  
    end   
  end
  
  def _update_rt(msg)
    self.remote_target = msg.contact.uri if msg.contact    
  end
  
  def remote_target=(rt)
    if @remote_target && @remote_target==rt
      @target_refreshed = false
      return
    end
    @remote_target = rt
    @target_refreshed = true
  end
  
  def target_refreshed?
    @target_refreshed  
  end
  
  private :_update_rt, :_assign_route_set
  
end
