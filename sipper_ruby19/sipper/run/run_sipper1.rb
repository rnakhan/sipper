$:.unshift File.join(File.dirname(__FILE__),"..")

require 'sipper'
require 'monitor'

class RunSipper1

  def initialize(file=nil)
    @cfile = file
  end
  
  def run
    Thread.current[:name] = "MainThread"
    SipperConfigurator[:ControllerPath] = :file_given if @cfile
    #Signal.trap("INT") { puts; exit }
    s = SIP::Sipper.new() 
    t = s.start 
    if @cfile
      cname = s.load_controller(IO.readlines(@cfile).join)
      s.start_controller_unless_sol(cname)
    end
    Signal.trap("INT") { puts; s.stop; exit }
    loop do 
      t.join(3)
      exit if s.exit_now
      Signal.trap("INT") { puts; s.stop; exit }
    end
  end
  
end
