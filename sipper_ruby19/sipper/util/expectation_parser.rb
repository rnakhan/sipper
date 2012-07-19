
# 1. Wilcard for responses only 2xx, 1xx, 18x etc for responses 
# 2. Alteration "< INVITE|SUBSCRIBE" optional request
# 3. Repetition "> INVITE  {2,2}" have exactly 2. "< 18x {2,3}" have 2 or 3.  "> 18x {,3}" at most 3" 
#   "> INVITE  {0,}" variable. "< BYE {1,} at least 1.
# 4. For wildcard responses the first character in the message MUST be a number like 1xx is valid as
#    is 41x but xxx or x00 is not valid. Character 'x' is used a wildcard.
# 5. The neutral expectation, the one recorded by the controller is recorded with the direction element
#    "!" and  the string should not contain any spaces.    
# An element is satisfied if the minimum requirement is met for that. 
# BNF Grammar is "DIRECTION  MSGEXPRESSION|MSGEXPREESION  REPETITION"

require 'sip_logger'
require 'strscan'
require 'util/sipper_util'
require 'ruby_ext/string'
require 'ruby_ext/object'

require 'facets/core/string/first_char'

module SipperUtil

  # one expectation element is like "< INVITE {1,2}" or "> 1xx {0,}"
  class ExpectationElement
    
    include SipLogger
    include SipperUtil
      
    Directions = ["<", ">", "!", "@"]
    MAX_REPEAT = 10000
    
    attr_accessor  :messages, :direction, :range, :satisfied
    
    def initialize(str)
      s = StringScanner.new(str)
      m = nil
      @direction = s.getch
      log_and_raise "Improper direction in exp str", ArgumentError unless Directions.include?(@direction)
      log_and_raise "Bad exp str, no space", ArgumentError unless s.scan(/\s+/) # space
      if s.exist?(/\s+/)
        m = s.scan_until(/\s+/).strip
      else
        m = s.scan_until(/$/)
      end
      @messages = m.split("|")
      log_and_raise "Bad exp str, no message", ArgumentError unless @messages
      # Enforce that wildcard is used rather than a check for say 200|202 etc for responses
      if @messages[0] =~ /^\d/ && @messages.length>0
        1.upto @messages.length-1  do |n|
          log_and_raise "Bad exp str, use wildcard instead of |", ArgumentError  if @messages[0][0] == @messages[n][0]  
        end
      end
      if s.eos?
        @range = Range.new(1,1)
      else
        rep = s.scan_until(/$/)
        log_and_raise "Bad repetition in exp str", ArgumentError unless(rep.first_char(1)=="{" && rep.last_char(1)=="}")  
        rep_str = rep[1...-1]
        min, max = rep_str.split(",")
        min = 0 unless (min && min.size>0)
        max = MAX_REPEAT unless (max && max.size>0)
        min = Integer(min)
        max = Integer(max)
        @range = Range.new(min, max)
      end
      @satisfied = false
    end
  
  end
  
  
  
  class ExpectationParser
    # expectations
    attr_accessor :exps
  
    def parse(ex_ary)
      @exps = []
      str = nil
      ex_ary.each {|str| @exps << ExpectationElement.new(str) } 
      @idx = 0
      @match_count = 0
    end
  
    # input string is "> INVITE" or "< 100" etc. 
    def match(str)
      d, m = str.split(" ")
      _match(d, m) 
    end
    
    # A recorded message will have a direction and message itself. 
    def _match(dir, message)
      return [false, nil] if @idx >= @exps.length
      matched = true
      matched = false if dir != @exps[@idx].direction
      if matched
        if dir == ::SipperUtil::ExpectationElement::Directions[2]  # "!" 
          matched = _match_neutral(message)
        elsif message.first_char(1).int?
          matched = _match_response(message)
        else
          matched = _match_request(message)
        end
      end
      if matched
        @match_count += 1
        return [true, nil] if @match_count < @exps[@idx].range.min
        return [false,_unmatched_expectation] if @match_count > @exps[@idx].range.max
        if @exps[@idx].range.include? @match_count
          @exps[@idx].satisfied = true 
          return [true, nil]
        end
      else
        if (@exps[@idx].satisfied || @exps[@idx].range.min == 0)
          @idx += 1
          @match_count = 0
          return _match(dir, message)  # match next
        else
          return [false,_unmatched_expectation]
        end
      end        
    end
  
    def _match_response(res)
      return false if res.length != 3
      matched = true
      m = nil
      @exps[@idx].messages.each do |m|
        return false unless m.first_char(1).int? 
        matched = true
        0.upto(2) do |n|
          unless m[n,1]=="x"
             if m[n] != res[n]
               matched = false 
               break
             end
          end
        end
        return true if matched
      end
      return matched
    end
    
    def _match_request(req)
      m = nil
      @exps[@idx].messages.each do |m|
        return true if m == req
      end
      return false
    end
    
    def _match_neutral(txt)
      m = nil
      @exps[@idx].messages.each do |m|
        return true if m == txt
      end
      return false
    end
    
    def _unmatched_expectation
      "#{@exps[@idx].direction} #{@exps[@idx].messages.join(' or ')} between #{@exps[@idx].range.min} and #{@exps[@idx].range.max}"
    end
    
    private :_unmatched_expectation, :_match_response, :_match_request, :_match
    
  end
  
end