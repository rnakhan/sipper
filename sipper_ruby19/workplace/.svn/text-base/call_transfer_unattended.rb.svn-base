#http://www.tools.ietf.org/html/draft-ietf-sipping-service-examples-14#section-2.4
#
# 2.4.  Transfer - Unattended
#
#
#          Alice                 Bob                 Carol
#            |      INVITE F1     |                    |
#            |<-------------------|                    |
#            |   180 Ringing F2   |                    |
#            |------------------->|                    |
#            |      200 OK F3     |                    |
#            |------------------->|                    |
#            |        ACK F4      |                    |
#            |<-------------------|                    |
#            |        RTP         |                    |
#            |<==================>|                    |
#            |                    |                    |
#            |  Alice performs unattended transfer     |
#            |                    |                    |
#            | REFER Refer-To:C F5|                    |
#            |------------------->|                    |
#            |  202 Accepted F6   |                    |
#            |<-------------------|                    |
#            |      NOTIFY F7     |                    |
#            |<-------------------|                    |
#            |      200 OK F8     |                    |
#            |------------------->|                    |
#            |       BYE F9       |                    |
#            |------------------->|                    |
#            |     200 OK F10     |                    |
#            |<-------------------|                    |
#            |   No RTP Session   | INVITE Referred-By: A F11
#            |                    |------------------->|
#            |                    |   180 Ringing F12  |
#            |                    |<-------------------|
#            |                    |     200 OK F13     |
#            |                    |<-------------------|
#            |                    |       ACK F14      |
#            |                    |------------------->|
#            |                    |        RTP         |
#            |                    |<==================>|
#            |      NOTIFY F15    |                    |
#            |<-------------------|                    |
#            |------------------->|                    |
#            |                    |                    |
#
# In this scenario, Bob calls Alice.  Alice then transfers Bob to Carol, then Alice disconnects with Bob. Bob establishes the session to Carol then reports the success back to Alice in the NOTIFY in F15.
# If the transfer fails, Bob can send a new INVITE back to Alice to re-establish the session. Despite the BYE sent by Alice in F9, the dialog between Alice and Bob still exists until the subscription created
# by the REFER has terminated (either due to a NOTIFY containing a Subscription-State:terminated;reason=noresource header field, as in F15, or a 481 response to a NOTIFY).
#
#
# 1. Bob is IUT.
#
# 2. Alice and carol are Sipper entities.The ports are configured in config file. 
#         
# 3. The variables :DefaultRIP, :DefaultRP may be present in config file, if not then the values must be provided through command line
# e.g 
#
#				srun -r 10.32.4.83 -o 5062 -t test.rb
#                                      \         /
#                                       \       /
#                                        \     /
#                                        IP & PORT on which IUT is running
#
# 4. Alice & Carol are configured for ports LocalSipperPort][1] & LocalSipperPort][0] respectively. So these port variables must be configured in config file, as mentioned
# :LocalSipperPort:
# - 5066
# - 5067
#
$:.unshift File.join(ENV['SIPPER_HOME'],'sipper_test')
require 'driven_sip_test_case'

class CallTransferUnattended < DrivenSipTestCase 

  def setup
    super
    SipperConfigurator[:SessionRecord]='msg-info'
    SipperConfigurator[:WaitSecondsForTestCompletion] = 180
    str = <<-EOF

#
require 'sip_test_driver_controller'
    
  module SipInline
  class UasReInvite2Controller < SIP::SipTestDriverController
      
  transaction_usage :use_transactions=>false
        
    def specified_transport
      [SipperConfigurator[:LocalSipperIP],SipperConfigurator[:LocalSipperPort][0]]
    end    
        
    def on_invite(session)
      session.respond_with(180)
      session.respond_with(200)
    end
        
    def on_bye(session)
      session.respond_with(200)
      session.invalidate(true)
      session.flow_completed_for("CallTransferUnattended")  
    end
      
 
  end


  class UasReInvite1Controller < SIP::SipTestDriverController 

  transaction_usage :use_transactions=>false
  
  def specified_transport
    [SipperConfigurator[:LocalSipperIP],SipperConfigurator[:LocalSipperPort][1]]
  end

  def on_ack(session)
    r = session.create_subsequent_request('REFER')
    r.refer_to = "<sip:carol@" + SipperConfigurator[:LocalSipperIP]+ ":" + SipperConfigurator[:LocalSipperPort][0].to_s + ">"
    r.refered_by = "<alice@" + SipperConfigurator[:LocalSipperIP]+ ":" + SipperConfigurator[:LocalSipperPort][1].to_s + ">"
    session.send(r)
  end
  
  def on_invite(session)
    session.respond_with(180)
    session.respond_with(200)
  end

  def start
    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])
  end
  
  def on_notify(session)
    session.respond_with(200)
    session.request_with('BYE')
  end
  
  def on_success_res_for_bye(session)
    session.invalidate(true)
  end  
  
end
end
    EOF
    
    define_controller_from(str)
    set_controller("SipInline::UasReInvite1Controller")
  end

  def self.description
    "In this scenario, Bob calls Alice.  Alice then transfers Bob to Carol, then Alice disconnects with Bob. Bob establishes the session to Carol then reports the success back to Alice in the NOTIFY in F15.
  If the transfer fails, Bob can send a new INVITE back to Alice to re-establish the session. Despite the BYE sent by Alice in F9, the dialog between Alice and Bob still exists until the subscription created
  by the REFER has terminated (either due to a NOTIFY containing a Subscription-State:terminated;reason=noresource header field, as in F15, or a 481 response to a NOTIFY)."
  end

  def test_case_1
    self.expected_flow = ['< INVITE','> 100 {0,}','> 180','> 200','< ACK','< BYE','> 200']
    start_controller
    verify_call_flow(:in, 1)
    
    self.expected_flow = ['< INVITE', '> 180','> 200','< ACK', '> REFER','< 202','< NOTIFY','> 200','> BYE','< 200']
    verify_call_flow(:in, 0)
    
  end
end
