# chkout http://dev.rubyonrails.org/browser/trunk/actionpack/Rakefile

require 'rake/clean'
require 'rake/testtask'

CLEAN.include("sipper/logs/*.log")
CLEAN.include("sipper/logs/*._in")
CLEAN.include("sipper/logs/*._out")
CLEAN.include("sipper/logs/precall*")
CLEAN.include("sipper/logs/.Test*")
CLEAN.include("sipper/logs/*_store")

task :default => [:test]

desc "Run all unit tests"
Rake::TestTask.new(:test) do |t|
  t.libs << "sipper_test"
  t.test_files= 
   (Dir.glob("sipper_test/test*.rb")-["sipper_test/test_remote_controller.rb", 
     "sipper_test/test_generated.rb", "sipper_test/test_media.rb", 
     "sipper_test/testmediacontroller.rb"])
  t.verbose = true
end

Rake::TestTask.new(:debug_some_tests) do |t|
  t.libs << "sipper_test"
  t.test_files= 
   ["sipper_test/test2xx_retransmission.rb", 
     "sipper_test/test_inline_controller.rb"]
  t.verbose = true
end


desc "Run generates tests"
Rake::TestTask.new(:generated_test) do |t|
  t.libs << "sipper_test"
  t.test_files = ["sipper_test/test_generated.rb"]
  t.verbose = true
end

desc "Run generates tests"
Rake::TestTask.new(:generated_pcap_test) do |t|
  t.libs << "sipper_test"
  t.test_files = ["sipper_test/test_pcap.rb"]
  t.verbose = true
end
			 

# order_tests.yaml file should be present
# in the tests directory for this ordering
# of tests to work. If not found then we
# default to built in test run task
desc "Run all unit tests in order"
task :my_test do
  require 'test/unit/ui/console/testrunner'
  require 'test/unit'
  Test::Unit.run = true
  path = File.join("sipper_test", "order_tests.yaml") 
  if File.exists?(path)
    a = File.open(path) {|yf| YAML::load(yf)}
  else
    Rake::Task["test"].execute 
    exit
  end 
  c = Dir.glob("sipper_test/*.rb")
  b = c.map {|f| f[12..-1]} # remove "sipper_test/"
  path = File.join("sipper_test", "order_tests.yaml") 
  if File.exists?(path)
    a = File.open(path) {|yf| YAML::load(yf)}
  else
    a = []
  end 
  test_files = a + (b - a)
  test_files.each do |tf|   
    load "sipper_test/"+tf
    Test::Unit::UI::Console::TestRunner.run(::Kernel.const_get(tf[0..-4].split("_").map! {|x| x.capitalize}.join))
  end
end


desc "Run all goblet unit tests"
Rake::TestTask.new(:goblet_test) do |t|
  t.libs << "goblet_test"
  t.test_files= 
   (Dir.glob("goblet_test/test*.rb"))
  t.verbose = true
end

desc "Print the total lines and lines of code (LOC)"
task :lines do
  lines, codelines, total_lines, total_codelines = 0, 0, 0, 0
 	
  for file_name in FileList["**/*.rb", "**/*.sm", "**/*.cpp", "**/*.h", "**/*.rhtml"]
    next if file_name =~ /vendor/
    f = File.open(file_name)

    while line = f.gets
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
    puts "L: #{sprintf("%4d", lines)}, LOC #{sprintf("%4d", codelines)} | #{file_name}"
   
    total_lines     += lines
    total_codelines += codelines
   
    lines, codelines = 0, 0
  end

  puts "Total: Lines #{total_lines}, LOC #{total_codelines}"
end
