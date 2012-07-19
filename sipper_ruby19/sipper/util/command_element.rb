# This is a generator helper class addding some commad level fucntionality in the generated
# code from the generate module. 

require 'sip_logger'
require 'strscan'
require 'util/sipper_util'
require 'ruby_ext/string'
require 'ruby_ext/object'

require 'facets/core/string/first_char'

module SipperUtil

  # One command element is like "@sleep 500" where the requirement is to add a sleep element for 500ms
  # in the genarted code. 
  # Since a CommandElement is used alongside the ExpectationElement we have a direction attribute 
  # returning "@" sign.
  # There is no space after @ sign for commands. The commands are methods defined on this class.  
  
  class CommandElement
    
    include SipLogger
    include SipperUtil
      
    # Command id is a general purpose id which can be used to identify/differentiate
    # commands.
    attr_reader  :command_str, :command, :command_id, :direction
    
    @@id_counter = 0
    
    def initialize(str)
      s = StringScanner.new(str)
      m = nil
      @direction = s.getch
      log_and_raise "Improper direction in cmd str", ArgumentError unless @direction == "@"
      m = s.scan_until(/$/)
      @command, *args = m.split
      log_and_raise "Bad command str, no command", ArgumentError unless @command
      @command_id = "id" + String(@@id_counter+=1)
      @command_str = self.send @command.to_sym, *args
    end
  
    # The command to make the flow sleep for specified amount of milliseconds. 
    # e.g. "@sleep_ms 500"
    def sleep_ms(ms) 
      flt_ms = Float(ms)
      log_and_raise "Negative argument is not allowed", ArgumentError if flt_ms < 0
      "sleep #{flt_ms/1000.0}" 
    end
    
    # Command to set a timer for this time, on expiration of this timer the next command or 
    # action is taken.  
    def set_timer(ms)
      flt_ms = Float(ms)
      log_and_raise "Negative argument is not allowed", ArgumentError if flt_ms < 0
      "session.schedule_timer_for(\"#{@command_id}\", #{flt_ms})"
    end
      
    
  end
  
end  