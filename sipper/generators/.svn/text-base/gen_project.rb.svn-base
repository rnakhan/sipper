
$:.unshift File.join(File.dirname(__FILE__),"..")

require 'fileutils'
require 'util/sipper_util'
require 'sipper_configurator'


module SIP
  module Generators
    class GenProject
      def initialize(projname, override=false)
        if override
          FileUtils.mkdir_p projname
        else
          FileUtils.mkdir projname
        end
        dir = File.join(File.dirname(__FILE__), 'project_template_dir')
        Dir.glob(dir+"/**/*").each do |f|
          n = f.split("project_template_dir/")[1]
          entity = File.join(projname, n)
          if File.directory?(f)
            puts "Creating ...... directory #{entity}"
            FileUtils.mkdir_p(entity)
          else
            puts "Creating ...... file #{entity}"
            FileUtils.cp(f, entity)  
          end
        end
        if SipperConfigurator[:GobletRelease]
          require 'goblet/sipper_ext/update_project'  
          Goblet::UpdateProject.new.update(projname)
        end
        FileUtils.mv(File.join(projname,"dot_sipper.proj"), File.join(projname, ".sipper.proj"))
        # now create the config for the project
        # log4r file
        FileUtils.cp File.join(File.dirname(__FILE__), "..", "config", "log4r.xml"), File.join(projname, "config")
        
        # Now set the project specific configuration
        proj_dir = File.join(Dir.pwd, projname)
        SipperConfigurator[:LogPath] = File.join(proj_dir, "logs")
        SipperConfigurator[:ConfigPath] = cfd = File.join(proj_dir, "config")
        SipperConfigurator[:ControllerPath] = File.join(proj_dir, "controllers")
        SipperConfigurator.write_yaml_file(File.join(SipperConfigurator[:ConfigPath], "sipper.cfg"))
      end
    end
  end
end
    