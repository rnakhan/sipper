module B2buaSessionMixin
  # Used exclusively for setting of a common b2bua lock to avoid deadlocks. 
  def use_b2b_session_lock_from(orig_session)
    @sq_lock = orig_session._get_sq_lock
    @non_anchor_leg = true
  end
  
  def revert_to_local_session_lock
    if @non_anchor_leg
      @sq_lock = ["free"] 
      @sq_lock.extend(MonitorMixin) 
      @non_anchor_leg = false
    end
  end  
  
  def b2b_anchor_leg?
    if @non_anchor_leg
      false
    else
      true
    end
  end
  
end
