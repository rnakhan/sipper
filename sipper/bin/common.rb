$:.unshift File.join(File.dirname(__FILE__), "..", "..", "sipper")

require 'fileutils'
require 'sipper_configurator'

module SipperUtil
  class Common
    @@project_dir = nil
    # Returns base proj dir if called from within a project directory. 
    def self.in_project_dir
      unless @@project_dir 
        dir = FileUtils.pwd
        try_files = [File.join(dir,".sipper.proj"), File.join(dir,"..",".sipper.proj"), File.join(dir,"..","..",".sipper.proj")]
        f = nil
        i = nil
        try_files.each_with_index do |f,i|  
          if File.exist? f 
            pd = case i
            when 0
              dir
            when 1
              File.join(dir,"..")
            when 2
              File.join(dir,"..","..")
            end
            @@project_dir =  pd
          end
        end
      end
      return @@project_dir
    end
    
    def self.set_environment
      dir = SipperUtil::Common.in_project_dir()
      if dir
        cf = File.join(dir, "config", "sipper.cfg")
        SipperConfigurator.load_yaml_file(cf) if File.exist? cf
      end
      dir
    end
    
  end  # class
  
  
  
end # module
