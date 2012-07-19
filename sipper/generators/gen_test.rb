require 'generators/gen_controller'
require 'facets/core/string/first_char'
require 'util/sipper_util'

module SIP
  module Generators
    class GenTest
      def initialize(tname, flow_str, pcap_arr=nil, filter=nil)
        @gen_class_name = SipperUtil.classify(tname)
        @gen_file_name = SipperUtil.filify(@gen_class_name)
        @flow_str = flow_str
	      @pcap_arr = pcap_arr
	      @filter = filter
        mod_flow_str = SipperUtil.make_expectation_parsable(flow_str)
        @flow = mod_flow_str.split("%").map {|str| str.strip}
        @direction = "neutral"
        case @flow[0].first_char(1)
        when SipperUtil::ExpectationElement::Directions[0]
          @direction = "in"
        when SipperUtil::ExpectationElement::Directions[1]
          @direction = "out"
        else
          @direction = "neutral"
        end
        @flow_msg_only = @flow.reject {|x| x.first_char(1) == "@"}
      end  
      
      def generate_test(write_to_file=false, dir = nil)

        @str = "require \'driven_sip_test_case\'\n\n"
        @str << sprintf("class %s < DrivenSipTestCase \n\n", @gen_class_name)
        @str << "  def self.description\n"
        @str << "    \"Callflow is #{@flow_str}\" \n"
        @str << "  end\n\n"
        @str << "  def setup\n"
        @str << "    super\n"
        @str << "    SipperConfigurator[:SessionRecord]='msg-info'\n"
        @str << "    SipperConfigurator[:WaitSecondsForTestCompletion] = 180\n"
        controller_code = Generators::GenController.new(@gen_class_name+"Controller", @flow_str, @pcap_arr, @filter, "SIP::SipTestDriverController").generate_controller(false)
        @str << "    str = <<-EOF\n"
        @str << controller_code
        @str << "    EOF\n"
        @str << "    define_controller_from(str)\n" 
        @str << "    set_controller('#{@gen_class_name}"+"Controller"+"')\n"
        @str << "  end\n\n"
        @str << "  def test_case_1\n"
        @str << "    self.expected_flow = " 
        @str << SipperUtil.print_arr(@flow_msg_only) + "\n"
        @str << "    start_controller\n"
        @str << "    if SipperConfigurator[:RunLoad] \n"
        @str << "      k = SipperConfigurator[:NumCalls]-1 \n"
        @str << "    else \n"
        @str << "      k = 0 \n"
        @str << "    end \n"
        @str << "    0.upto(k) {|x| verify_call_flow(x)}\n"
        @str << "  end\n"      
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
      
    end
  end
end

if $PROGRAM_NAME == __FILE__
  g = SIP::Generators::GenTest.new(ARGV[0], ARGV[1])
  g.generate_test
end
