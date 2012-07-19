#todo have a rake task
#todo look for ruby code formatter

$:.unshift File.join(File.dirname(__FILE__),"..")

require 'fileutils'
require 'util/sipper_util'
require 'util/expectation_parser'
require 'util/command_element'
		  
module SIP
  module Generators
    class GenController
    
      def initialize(cname, flow_str, pcap_arr=nil, filter=nil, ctype="SIP::BaseController")
        if cname =~ /^[A-Z]/
          _cname = cname
        else
          _cname = SipperUtil.classify(cname)  
        end
         
        if _cname =~ /Controller$/
          @gen_class_name = _cname
        else
          @gen_class_name = _cname + "Controller"
        end
        @gen_file_name = SipperUtil.filify(@gen_class_name)
        @flow_str = flow_str
        @pcap_arr = pcap_arr
        @filter = filter
        @ctype = ctype
        
        @d_in  = SipperUtil::ExpectationElement::Directions[0]  # < inward
        @d_out = SipperUtil::ExpectationElement::Directions[1]  # > outward
        @d_n   = SipperUtil::ExpectationElement::Directions[2]  # ! neutral
        @d_c   = SipperUtil::ExpectationElement::Directions[3]  # @ command
        
        #mod_flow_str = flow_str.gsub(/\{(.*?)\}/, '') # remove {...} for controller
        mod_flow_str = SipperUtil.make_expectation_parsable(flow_str)
        @flow = mod_flow_str.split("%").map {|str| str.strip}.map do |e| 
          if e.index(@d_c) == 0
            SipperUtil::CommandElement.new(e)
          else
            SipperUtil::ExpectationElement.new(e)
          end
        end
        
        
        @current_method = ["start"]      # you always start at start()
        @method_code = {"start" => ""}
        @method_code_lines = {"start" => 0}
        @processing_under_state_check = false
      end
      
      def generate_controller(write_to_file=false, dir = nil)    
        @str = "# FLOW : #{@flow_str}\n#\n"
        @str << "require \'base_controller\'\n\n"
        @str << sprintf("class %s < %s \n\n", @gen_class_name, @ctype)
        @str << "  # change the directive below to true to enable transaction usage.\n"
        @str << "  # If you do that then make sure that your controller is also \n"
        @str << "  # transaction aware. i.e does not try send ACK to non-2xx responses,\n"
        @str << "  # does not send 100 Trying response etc.\n\n"
        @str << "  transaction_usage :use_transactions=>false\n\n"
        if @ctype == "SIP::BaseController"
          @str << "  # change the directive below to true to start after loading.\n"
          @str << "  start_on_load false\n\n"
        end
        
        @str << "  def initialize\n"
        @str << "    logd('Controller created')\n  end\n\n"
        @method_code["start"] << "  def start\n"
        @method_code["start"] << "    session = create_udp_session(SipperConfigurator[:DefaultRIP], SipperConfigurator[:DefaultRP])\n"
        @flow.each do |e|
          if e.direction == @d_in  # have a new method defined for each incoming and repeat outgoing
            @current_method = []
            e.messages.each do |m| 
              k = m.sub(/^\d../, m[0,1]+"xx")
              _get_message(k); 
              @current_method << k  
            end
          elsif e.direction == @d_out 
            @current_method.each do |c_method|
              # if there is a "|" condition for sending then generate a warning.
              puts "Warning: Sending optional messages is not permitted, taking #{e.messages[0]} only." if e.messages.length>1
	      if @pcap_arr == nil
                _send_message(e.messages[0], c_method)
	      else
	        _send_pcap_message(e.messages[0], c_method, @pcap_arr, @filter)
	      end	
            end
          elsif e.direction == @d_n # neutral
            @current_method.each do |c_method|
              puts "Warning: Logging optional messages is not permitted, taking #{e.messages[0]} only." if e.messages.length>1
              _log_message(e.messages[0], c_method)
            end
          elsif e.direction == @d_c # command
            @current_method.each do |c_method|
              _command(e.command_str, c_method)
            end
            if e.command == "set_timer"
              unless @method_code["timer"]
                @method_code["timer"] = "  def on_timer(session, task)\n"
              else
                @method_code["timer"] << "    end\n" # closing end for if tid 
              end
              @method_code["timer"] << "    if task.tid == \"#{e.command_id}\"\n"
              @current_method = ["timer"]
            end
          end  
        end
        
        @current_method.each do |m|
          @method_code[m] << "    session.invalidate(true)\n"
          if @ctype == "SIP::SipTestDriverController"
            test_name = @gen_class_name.sub(/Controller/,"") # by convention the "Controller" is appended to named test 
            @method_code[m] << "    session.flow_completed_for('#{test_name}')\n" 
          end
        end
        _close_all_methods
        
        @str << "end\n"  # close class
        if write_to_file
          if dir
            f = File.join(dir, @gen_file_name)
          else
            f = @gen_file_name
          end
          cfile = File.new(f, "w")
          cfile << @str
          cfile.close
        end
        @str
      end  
      
      def _get_message(msg)
        unless @method_code[msg]
          @method_code_lines[msg] = 0
          @processing_under_state_check = false
          case msg 
          when /^[A-Z]/
            @method_code[msg] = "  def on_#{msg.downcase}(session)\n" 
          when /^100/
            @method_code[msg] = "  def on_trying_res(session)\n" 
          when /^1/
            @method_code[msg] = "  def on_provisional_res(session)\n" 
          when /^2/
            @method_code[msg] = "  def on_success_res(session)\n" 
          when /^3/
            @method_code[msg] = "  def on_redirect_res(session)\n" 
          else
            @method_code[msg] = "  def on_failure_res(session)\n" 
          end
        else 
          # method already exists, now just add the if/else check for
          # state. 
          _add_state_check_for(msg) 
          @processing_under_state_check = true
        end
      end
      
      
      def _send_message(msg, method)
        sp = self._spacing    
        if msg =~ /^[A-Z]/    
          @method_code[method] << "#{sp}session.request_with('#{msg}'"
          if method == "start"
            @method_code[method] << ", 'sip:nasir@sipper.com')" 
          else 
            @method_code[method] << ")"
          end
          @method_code[method] << "\n"
        else
          @method_code[method] << "#{sp}session.respond_with(#{msg})\n"
        end
      end
      
      def _send_pcap_message(msg, method, pcap_arr, filter)
        system_headers = ["call_id","from","to","cseq","via","contact","max_forwards", "content", "p_sipper_session"]
        pcap_request = pcap_arr.shift      
        sp = self._spacing
        if msg =~ /^[A-Z]/
          if method == "start"
            @method_code[method] << "#{sp}r = session.create_initial_request('#{msg}'"
            @method_code[method] << ", 'sip:nasir@sipper.com')"
          else
            @method_code[method] << "#{sp}r = session.create_subsequent_request('#{msg}'"
            @method_code[method] << ")"
          end
          @method_code[method] << "\n"
        else
          @method_code[method] << "#{sp}r = session.create_response(#{msg})\n"
        end

        pcap_request.each_header do |h|
          exestr = "pcap_request." + h.to_s
          if not system_headers.include?(h.to_s)
            val = eval(exestr).to_s.gsub(filter,'SipperConfigurator[:LocalSipperIP]')
            if val.index('SipperConfigurator[:LocalSipperIP]')!= nil
              start_index = val.index('SipperConfigurator[:LocalSipperIP]') 
              len = "SipperConfigurator[:LocalSipperIP]".length
              if val.index('SipperConfigurator[:LocalSipperIP]')!= 0
                if val.reverse.index('SipperConfigurator[:LocalSipperIP]'.reverse)!= 0 
                  val = '"'+ val[0...start_index] + '" + SipperConfigurator[:LocalSipperIP] + "' + val[start_index+len..-1]+ '"'
                else
                  val = '"'+ val[0...start_index] + '" + SipperConfigurator[:LocalSipperIP]'
                end
              elsif val.reverse.index('SipperConfigurator[:LocalSipperIP]'.reverse)!= 0
                val = val[0...start_index] + 'SipperConfigurator[:LocalSipperIP] + "' + val[start_index+len..-1]+ '"'
              else 
                val = val[0...start_index] + 'SipperConfigurator[:LocalSipperIP]'
              end
              @method_code[method] << "#{sp}r." + h.to_s + " = " +val
              @method_code[method] << "\n"
            else
              @method_code[method] << "#{sp}r." + h.to_s + ' = "' + val + '"'
              @method_code[method] << "\n"
            end  
          end
        end
        if pcap_request.content_length.to_s.to_i > 0
          @method_code[method] << "#{sp}r.content" + ' = "' + pcap_request.contents.join("\n") + '"'
          @method_code[method] << "\n"
        end
        @method_code[method] << "#{sp}session.send(r)"
        @method_code[method] << "\n"
      end
		  
      def _log_message(msg, method)
        sp = self._spacing
        @method_code[method] << "#{sp}session.do_record('#{msg}')\n" 
      end
      
      def _command(cmd, method)
        sp = self._spacing
        @method_code[method] << "#{sp}#{cmd}\n"     
      end
      
      def _spacing
        sp = "  "
        if @processing_under_state_check
            sp = " "*6
        else
            sp = " "*4
        end 
        return sp
      end
      
      def _add_state_check_for(msg) 
        count = 0
        cond_str = "session['#{msg.downcase}']"
        code_arr = @method_code[msg].split("\n")
        if @method_code[msg].index(cond_str)
          count = @method_code[msg].scan(cond_str+ " = ").length  # count session['info'] = n
          code_arr.insert(-1, "    #{cond_str} = #{count + 1}\n")
          code_arr.insert(-1, "    elsif #{cond_str} == #{count+1}\n")
        else
          code_arr.insert(1, "    if !#{cond_str}")
          code_arr[2] = "  " + code_arr[2] if code_arr[2] # re-format current message line
          code_arr.insert(-1, "      #{cond_str} = 1")
          code_arr.insert(-1, "    elsif #{cond_str} == 1\n")
        end  
        @method_code[msg] = code_arr.join("\n")
      end
      
      
        
      def _close_method(msg)
        @method_code[msg] << "\n    end\n" if @method_code[msg].index("if session['")
        @method_code[msg] << "    end\n" if msg == "timer"
        @method_code[msg] << "  end\n\n" 
        @str << @method_code[msg]
      end
      
      def _close_all_methods
        @method_code.each_key {|k| _close_method(k)}
      end
      
    end
  end
end

if $PROGRAM_NAME == __FILE__
  g = SIP::Generators::GenController.new(ARGV[0], ARGV[1])
  g.generate_controller(true)
end
