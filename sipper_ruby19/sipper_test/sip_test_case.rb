unless $ULOGNAME
  x = File.basename($0)[0...-3]
  $ULOGNAME = '_'+x unless x =~/rake_test_loader/
end
require 'base_test_case'
require 'bin/common'

class SipTestCase < BaseTestCase
  include SipperAssertions
  
  attr_accessor :current_controller
  
  @@now_running = "SipTestCase"
  
  def setup
    super
	name = ""
    Thread.current[:name] = "TestMainThread"+name
    if @@now_running != self.class.name
      @@now_running = self.class.name  
      setup_once
    end
    @grty = SIP::Locator[:Sth].granularity
  end
  
  
  def setup_once
    SIP::Locator[:Sipper].stop if SIP::Locator[:Sipper].running if SIP::Locator[:Sipper] 
    SipperConfigurator[:LocalTestPort] ||= SipperUtil::Common.in_project_dir() ? SipperConfigurator[:LocalSipperPort]||5060 : 5066
    if SipperConfigurator[:LocalTestPort].class == Array
      s = SIP::Sipper.new(:Ports=>SipperConfigurator[:LocalTestPort])
    else
      s = SIP::Sipper.new(:Ports=>[SipperConfigurator[:LocalTestPort]])
    end
    s.start
    @grty = SIP::Locator[:Sth].granularity
  end

  # Define the controller(s) specified in the string.
  def define_controller_from(str)
    SIP::Locator[:Sipper].load_controller(str)
  end

  def set_controller(name)
    @current_controller = SIP::Locator[:Cs].get_controller(name)
  end

  
  def start_named_controller(name, in_mem_rec=false)
    set_controller(name)
    start_controller(in_mem_rec)
  end
  
  def start_controller(in_mem_rec=false)
    start_the_set_controller(in_mem_rec) 
  end
  
  def start_the_set_controller(in_mem_rec)
    raise RuntimeError, "No controller set"  unless @current_controller
    @rio = StringIO.new  if in_mem_rec 
    @current_controller.start { @rio }  
  end
  protected :start_the_set_controller
  
  def get_neutral_recording(idx=0)
    neutral_files = Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*_neutral")).sort 
    SessionRecorder.load(neutral_files[idx])
  end
  
  # The "in" recording is special in such that the UAS works in the context of a worker
  # thread. There is no easy way to signal a waiting DrivenSipTestCase so in this case
  # we rely on a File Lock for the recording file or mutex signaling 
  def get_in_recording(idx=0)
    str = File.join(SipperConfigurator[:SessionRecordPath], "*_in")
    # in_files = Dir.glob(str).sort{|a,b| File.ctime(a)<=>File.ctime(b)}

    in_files = Dir.glob(str).sort
    SessionRecorder.load(in_files[idx])
  end
  
  def get_out_recording(idx=0)
    if @rio
      @rio.rewind
      SessionRecorder.load( @rio )
    else
      str = File.join(SipperConfigurator[:SessionRecordPath], "*_out")
      out_files = Dir.glob(str).sort
      #out_files = Dir.glob(str).sort{|a,b| File.ctime(a)<=>File.ctime(b)}
      SessionRecorder.load(out_files[idx])
    end
  end
  
  
  
  def teardown
    
    Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*_in")).each {|f| File.delete(f)}
    Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*_out")).each {|f| File.delete(f)}
    Dir.glob(File.join(SipperConfigurator[:SessionRecordPath], "*_neutral")).each {|f| File.delete(f)}
    SessionManager.clean_all
    super
  end
  
    
end
