require 'session'
require 'sip_logger'

class Registration
  include SipLogger
  
  class RegistrationData
    attr_accessor :contact_uri, :expires, :q, :timestamp, :contact, :path
    def initialize(contact)
      @contact = contact  
    end
  end
  
  def Registration.add_registration_data(contact, request)
    reg_data = RegistrationData.new(contact.to_s)
    reg_data.contact_uri = contact.uri
        
    if contact[:expires] : reg_data.expires = contact.expires
    elsif request[:expires] : reg_data.expires = request.expires.header_value
    else reg_data.expires = "3600"
    end
    
    reg_data.q = contact[:q] ? contact.q : 0
    reg_data.timestamp = Time.now
    reg_data.path = request[:path]? request.path : nil
    return reg_data
  end
  
  def Registration.update_registration_data(contact, reg_list, request)
    updated = false
    reg_list.each do |registration|
      if registration.contact_uri == contact.uri
        index = reg_list.index(registration)
        if contact[:expires] : registration.expires = contact.expires 
        elsif request[:expires] : registration.expires = request.expires.header_value
        else registration.expires = "3600"
        end
        registration.q = contact[:q] ? contact.q : 0
        registration.timestamp = Time.now
        registration.path = request[:path]? request.path : nil
        if registration.expires.to_i == 0
          reg_list.delete_at(index)
        else  
          reg_list[index] = registration
        end  
        updated =true
      end
    end  
    return updated
  end
  
  
  
end
