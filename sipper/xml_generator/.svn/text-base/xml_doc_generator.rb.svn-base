require 'rexml/document'
require 'stringio'

module XmlDoc
  class RegInfoDoc
    include REXML      
    #creates the registration information document (reginfo+xml) defined in RFC 3680
    #the current implementation supports only one 'registration' sub-element for an address-of-record.
    #the document contains the "full" registration state.
    #the contact elements supports the mandatory attributes: id, state and event
    # The arguments are the AOR, document version
    # and an array of Contact addresses. If contact address is nil, it picks the contacts from RegistrationStore 
    def self.create(aor, ver, contacts)
      doc = Document.new
      doc << XMLDecl.new
      reginfo = Element.new 'reginfo'
      reginfo.attributes["xmlns"] = 'urn:ietf:params:xml:ns:reginfo'
      reginfo.attributes["version"]= ver.to_s
      reginfo.attributes["state"]='full'
      
      regis = Element.new 'registration'
      reg_list = contacts ? contacts.to_a : SIP::Locator[:RegistrationStore].get(aor) 
      regis.attributes['aor']= aor
      regis.attributes['id']='a7'
      
      unless reg_list
        regis.attributes['state']='init'
      else
        regis.attributes['state']='active'
      
        reg_list.each do |data|
          contact = Element.new 'contact'
          contact.attributes['id'] = reg_list.index(data).to_s
          contact.attributes['state'] ='active'
          contact.attributes['event'] ='registered'
          uri = Element.new 'uri'
          uri.text = contacts ? data : data.contact_uri
          contact.add_element uri
          regis.add_element contact  
        end
      end  
      reginfo.add_element regis
      doc.add_element reginfo
      doc
    end
        
  end


  #Class representing the pidftuple  
  class PidfTuple
    attr_accessor :tuple_id, :status, :contact_addr, :contact_priority, :tuple_note, :timestamp
  
    #All the parameters are optional. tuple_id and timestamp are initilized here by default. 
    def initialize(status=nil, contact_addr=nil, contact_priority=nil, tuple_note=nil)
      @tuple_id = rand(1000).to_s
      @status = status 
      @contact_addr = contact_addr
      @contact_priority = contact_priority
      @tuple_note = tuple_note
      @timestamp = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
    end  
  end
  
  class PidfDoc
    include REXML
    #creates the PIDF document (pidf+xml) defined in RFC 3863
    #this implementation supports any number of tuple and note elements.
    #Arguments are the entity, array of PidfTuple and array of presence_note.
    def self.create(entity,pidftuple=nil,presence_note=nil)
      doc = Document.new
      doc << XMLDecl.new 
      presence = Element.new 'presence'
      presence.attributes["xmlns"] = 'urn:ietf:params:xml:ns:pidf'
      entity = entity.to_s.gsub('sip:','pres:')
      presence.attributes["entity"] = entity
      
      if pidftuple
        tuple_list = pidftuple.class.to_s.include?('Array')? pidftuple : [pidftuple]
      
        tuple_list.each do |data|
          tuple = Element.new "tuple"
          tuple.attributes["id"] = data.tuple_id
        
          status = Element.new "status"
          if data.status
            basic = Element.new "basic"
            basic.text = data.status
            status.add_element basic
          end
        
          if data.contact_addr
            contact = Element.new "contact" 
            contact.attributes["priority"] = data.contact_priority if data.contact_priority
            contact.text = data.contact_addr
            tuple.add_element contact
          end
        
          if data.tuple_note
            comment = Element.new "note" 
            comment.text = data.tuple_note
            tuple.add_element comment
          end
        
          time = Element.new "timestamp"
          time.text = data.timestamp
          tuple.add_element time
          presence.add_element tuple
        end
      end
      presence_note_list = presence_note.to_a
      
      presence_note_list.each do |data|
        note = Element.new "note"
        note.text = data
        presence.add_element note
        
      end
      
      doc.add_element presence
      return doc  
    end
    
  end

end