require 'test/unit/ui/testrunnermediator'
require 'test/unit/ui/testrunnerutilities'
require "rubygems"
require "ruport"
require "ruport/util"

require 'bin/common'


module Test
  module Unit
    module UI
      module Report
        
        class TestRunner
          extend TestRunnerUtilities
          
          
          def initialize(suite, output_level=NORMAL)
            if (suite.respond_to?(:suite))
              @suite = suite.suite
            else
              @suite = suite
            end
            @output_level = output_level
            
            dir = SipperUtil::Common.in_project_dir()
            if dir
              @rd = File.join(dir, "reports")
              #rd = File.join(SipperConfigurator[:LogPath], "reports")
              FileUtils.mkdir_p @rd
              t = Time.now
              @name = t.strftime("%y%m%d_%H%M%S")
              @csv_file = File.join(@rd, @name+".csv")
              @io = File.new(@csv_file, "w+")
            else  
              @io = STDOUT
            end
            output("Category, Test Name,Test Case,Result,Assertions, Detail")
            @console_io = STDOUT
            @already_outputted = false
            @faults = []
            @test_class_names = []
          end
          
          # Begins the test run.
          def start
            setup_mediator
            attach_to_mediator
            return start_mediator
          end
          
          private
          def setup_mediator
            @mediator = create_mediator(@suite)
            suite_name = @suite.to_s
            if ( @suite.kind_of?(Module) )
              suite_name = @suite.name
            end
            console_output("Loaded suite #{suite_name}")
          end
          
          def create_mediator(suite)
            return TestRunnerMediator.new(suite)
          end
          
          def attach_to_mediator
            @mediator.add_listener(TestResult::FAULT, &method(:add_fault))
            @mediator.add_listener(TestRunnerMediator::STARTED, &method(:started))
            @mediator.add_listener(TestRunnerMediator::FINISHED, &method(:finished))
            @mediator.add_listener(TestCase::STARTED, &method(:test_started))
            @mediator.add_listener(TestCase::FINISHED, &method(:test_finished))
          end
          
          def start_mediator
            return @mediator.run_suite
          end
          
          def add_fault(fault)
            @faults << fault
            console_output_single(fault.single_character_display, PROGRESS_ONLY)
            @already_outputted = true
            if fault.single_character_display=='F'
              output_single("FAIL,") unless (@in_same_class)
            else 
              output_single("ERROR,") unless (@in_same_class)
            end
            print_assertions unless (@in_same_class)
            if !(@in_same_class)
              output_single(",")
            else
              output_single( '<br/><br/>')
            end 
            @in_same_class =true
            output_single(fault.long_display.split("\n").join(" ; "))
          end
          
          def started(result)
            @result = result
            console_output("Started reporting")
            @last_assertion_count = @result.assertion_count
          end
          
          def finished(elapsed_time)
            console_nl
            console_output("Finished reporting in #{elapsed_time} seconds.")
            @faults.each_with_index do |fault, index|
              console_nl
              console_output("%3d) %s" % [index + 1, fault.long_display])
            end
            console_nl
            console_output(@result)
            @io.close
            t = Table(@csv_file)
            t.remove_column("Test Case")
            grouping = Grouping(t,:by => "Category")
             
            #pdf_content = grouping.to_pdf
            mdata = {:total=>@result.run_count, 
                     :ac=>@result.assertion_count,
                     :fc=>@result.failure_count,
                     :ec=>@result.error_count,
                     :cn=>@test_class_names,
                     :data => grouping}
                 
            html_content = HtmlController.render(:html, :data => mdata)
          
            #pdf_file = File.join(@rd, @name+".pdf")
            html_file = File.join(@rd, @name+".html")
            #pdf_io = File.new(pdf_file, "w+")
            #pdf_io.write(pdf_content)
            #pdf_io.flush
            #pdf_io.close
            html_io = File.new(html_file, "w+")
            html_io.write(html_content)
            html_io.flush
            html_io.close
          end
          
          def test_started(name)
            class_name_idx = name.index("(")
            class_name = name[class_name_idx+1...-1]
            test_name = name[0...class_name_idx]
            if class_name.index('::')
              group_name,class_name = class_name.split('::')
            else 
              group_name = "Tests"
            end
            output_single(group_name + ",")
            output_single(class_name + ",")
            output_single(test_name + ",")
            @test_class_names << class_name
          end
          
          def test_finished(name)
            console_output_single(".", PROGRESS_ONLY) unless (@already_outputted)
            console_nl(VERBOSE)
            output_single("PASS,") unless (@already_outputted)
            print_assertions unless (@already_outputted)
            output_single(",")
            output_single("")
            @already_outputted = false
            @in_same_class =false
             nl(1)
          end
          
          def print_assertions
            output_single(@result.assertion_count-@last_assertion_count)
            @last_assertion_count = @result.assertion_count  
          end
          
          def nl(level=NORMAL)
            output("", level)
          end
          
          def console_nl(level=NORMAL)
            console_output("", level)
          end
          
          def output(something, level=NORMAL)
            @io.puts(something) if (output?(level))
            @io.flush
          end
          
          def console_output(something, level=NORMAL)
            @console_io.puts(something) if (output?(level))
            @console_io.flush
          end
          
          def output_single(something, level=NORMAL)
            @io.write(something) if (output?(level))
            @io.flush
          end
          
          def console_output_single(something, level=NORMAL)
            @console_io.write(something) if (output?(level))
            @console_io.flush
          end
          
          def output?(level)
            level <= @output_level
          end
        end
      end
    end
  end
end

if __FILE__ == $0
  Test::Unit::UI::Console::TestRunner.start_command_line_test
end