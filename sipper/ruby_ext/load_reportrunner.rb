
require 'test/unit/ui/testrunnermediator'
require 'test/unit/ui/testrunnerutilities'
require "rubygems"
require "ruport"
require "ruport/util"

require 'bin/common'
require 'sipper_configurator'

module Test
  module Unit
    module UI
      module LoadReport
        
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
              FileUtils.mkdir_p @rd
              t = Time.now
              @name = t.strftime("%y%m%d_%H%M%S")
              @csv_file = File.join(@rd, @name+".csv")
              @io = File.new(@csv_file, "w+")
            else  
              @io = STDOUT
            end
            output("Timestamp, Succeeded Assertions,Failed Assertions,Errors")
            @console_io = STDOUT
            @already_outputted = false
            @faults = []
            @succ_count = 0
            @fail_count = 0
            @err_count = 0
            @emit_after_count = SipperConfigurator[:StfLoadReportFrequency] || 10
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
            @mediator.add_listener(TestResult::CHANGED, &method(:add_run))
            @mediator.add_listener(TestRunnerMediator::STARTED, &method(:started))
            @mediator.add_listener(TestRunnerMediator::FINISHED, &method(:finished))
            #@mediator.add_listener(TestCase::STARTED, &method(:test_started))
            #@mediator.add_listener(TestCase::FINISHED, &method(:test_finished))
          end
          
          def start_mediator
            return @mediator.run_suite
          end
          
          def add_fault(fault)
            @faults << fault
            console_output_single(fault.single_character_display, PROGRESS_ONLY)
            @already_outputted = true
            if fault.single_character_display=='F'
              @fail_count += 1
            else 
              @err_count += 1
            end
          end
          
          def add_run(result)
            if result.passed?
              @succ_count += 1
              if (@succ_count%@emit_after_count == 0)
                emit_row()
              end
            end  
          end 
          
          def started(result)
            @result = result
            console_output("Started load, view the CSV file under reports for results")       
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
            #emit_row()
            @io.close     
          end
          
          def test_started(name) 
          end
          
          def test_finished(name)
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
          
          def emit_row()
            str = "#{Time.now.to_i}, #{@succ_count}, #{@fail_count}, #{@err_count}"
            output(str)
          end
          
          def output(something, level=NORMAL)
            if (output?(level))
              @io.write(something + "\n")
            end
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