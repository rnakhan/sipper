require 'sipper_configurator'
require 'bin/common'
dir = SipperUtil::Common.in_project_dir()
if dir
  cf = File.join(dir, "frwk_ext")
  if File.exists?(cf)
    Dir[File.join(cf, '**/*.rb')].each {|f| load f}
  end
end
Dir[File.join(File.dirname(__FILE__), 'lib/**/*.rb')].each {|l| load l}
$:.unshift File.join(File.dirname(__FILE__),"lib")
$:.unshift File.join(File.dirname(__FILE__),"lib", "smc")

require 'statemap'

require 'util/sipper_util'
require 'ruby_ext/object'
require 'ruby_ext/string'
require 'sip_logger'
require 'transport/base_transport'
require 'transport/udp_transport'
require 'transport/tcp_transport'
require 'sip_message_router'
require 'transport_manager'
require 'controller_selector'
require 'controller_class_loader'
require 'util/locator'
require 'test_completion_signaling_helper'
require 'util/timer/timer_manager'
require 'util/timer/sip_timer_helper'
require 'util/persistence/ps_sipper_map'
require 'util/persistence/csv_sipper_map'
require 'version'
require 'message'
require 'request'
require 'response'
require 'fileutils'
require 'custom_message'

require 'socket'
require 'monitor'
require 'drb/drb'

require 'base_controller'
require 'sip_test_driver_controller'


require 'media/sipper_media_proxy'
require 'media/sipper_media_manager'

require 'sipper_http/sipper_http_request_dispatcher'

module SIP
  class Sipper 
    include SipLogger  
    
    attr_reader :running, :exit_now
    
    def initialize( config={} )
      @ilog = logger
      if (RUBY_PLATFORM =~ /mswin/) || (RUBY_PLATFORM =~ /i386-mingw32/)
        SipperConfigurator[:SipperPlatformRecordingSeparator] = "\r\n"
      elsif
        RUBY_PLATFORM =~ /linux/
        SipperConfigurator[:SipperPlatformRecordingSeparator] = "\n"
      end
      
      # If user has provided the file from the command line using -c
      # option then we should not try to load controllers from the 
      # controlle path, this further ensures that even in project settings
      
      file_given = true if SipperConfigurator[:ControllerPath] == :file_given
      #SipperUtil::Common.set_environment()
      SipperConfigurator[:ControllerPath] = :file_given if file_given
      if config[:Ips]
        ips = config[:Ips]
      else
        SipperConfigurator[:LocalSipperIP] = "127.0.0.1" unless SipperConfigurator[:LocalSipperIP]
        if SipperConfigurator[:LocalSipperIP].class == Array
          ips = SipperConfigurator[:LocalSipperIP]
        else
          ips = [SipperConfigurator[:LocalSipperIP]]
        end  
      end
      
      if config[:Ports]
        ports = config[:Ports]
      else
        SipperConfigurator[:LocalSipperPort] = 5060 unless SipperConfigurator[:LocalSipperPort]
        if SipperConfigurator[:LocalSipperPort].class == Array
          ports = SipperConfigurator[:LocalSipperPort]
        else
          ports = [SipperConfigurator[:LocalSipperPort]]
        end
      end
      
      # check for asymmetrical config 
      diff = ips.length - ports.length
      
      if diff > 0
        diff.times do 
          ports << ports[-1]  
        end
      elsif diff < 0   
        pdiff = -1 * diff
        pdiff.times do
          ips << ips[-1]  
        end
      end
      
      # Make sure ip port tuples are unique
      if ips.length > 1
        tuples = []
        ips.each_with_index do |ip, i|
          tuples << [ip, ports[i]]
        end
        tuples.uniq!
        ips = []
        ports = []
        tuples.each do |t|
          ips << t[0]       
          ports << t[1]     
        end
      end
      
      if config[:Transports]
        transports = config[:Transports]
      else
        SipperConfigurator[:LocalSipperTransports] = "udp" unless SipperConfigurator[:LocalSipperTransports]
        if SipperConfigurator[:LocalSipperTransports].class == Array
          transports = SipperConfigurator[:LocalSipperTransports]
        else
          transports = [SipperConfigurator[:LocalSipperTransports]]
        end
      end
      
      # check for asymmetrical config 
      diff = ips.length - transports.length
      
      if diff > 0
        diff.times do 
          transports << "udp"  
        end
      end
      
      SipperConfigurator[:ControllerPath] ||= config[:ControllerPath]
      
      SipperConfigurator[:DefaultRIP] ||= "127.0.0.1"
      SipperConfigurator[:DefaultRP] ||= 5060
      
      @q = Queue.new # the message queue
      SIP::Locator[:Tm] = TransportManager.new
      
      # Each transport uses the same queue
      ports.length.times do |i|
        transports[i].split("_").each do |tp|
          case tp.downcase
          when "udp"
            SIP::Locator[:Tm].add_transport(::Transport::UdpTransport.instance(ips[i]?ips[i]:ips[0], ports[i], @q))
          when "tcp"
            SIP::Locator[:Tm].add_transport(::Transport::TcpTransport.instance(ips[i]?ips[i]:ips[0], ports[i], @q))
          else
            log_and_raise "The transport #{tp} is not yet supported"
          end
        end
        #@ilog.info("Created the transport #{ips[i]?ips[i]:ips[0]}, #{ports[i]}") if @ilog.info?
      end
      @ilog.info("Added #{ports.length} ports to transport manager") if @ilog.info?
      SipperConfigurator[:NumThreads] ||=  config[:NumThreads] || 5
      @smr = SipMessageRouter.new(@q, SipperConfigurator[:NumThreads])
      SIP::Locator[:Smr] = @smr
      @running = false
      if SipperConfigurator[:TimerGranularity]
        @tm = SIP::TimerManager.new(@q, SipperConfigurator[:TimerGranularity])
      else
        @tm = SIP::TimerManager.new(@q)
      end
      
      if SipperConfigurator[:SipperMedia]
        SIP::Locator[:Smd] = Media::SipperMediaProxy.new
        Media::SipperMediaManager.instance.set_queue(@q)
      end
      
      # Location service store / for registrar
      # Location service store / for dialog store
      if SipperConfigurator[:SipperPersistentStore] == 'db'
        raise "This is a sipper installation and DB is not supported here. 
        Upgrade to Goblet for DB support" unless SipperConfigurator[:GobletRelease]
        require 'util/persistence/db_sipper_map'
        SIP::Locator[:RegistrationStore] = SipperUtil::Persistence::DbSipperMap.new("registration_store")
        SIP::Locator[:DialogInfoStore] = SipperUtil::Persistence::DbSipperMap.new("dialog_info_store")
      else
        SIP::Locator[:RegistrationStore] = SipperUtil::Persistence::PsSipperMap.new("registration_store")
        SIP::Locator[:DialogInfoStore] = SipperUtil::Persistence::PsSipperMap.new("dialog_info_store")
      end  
      
      # To be used for simple password DB
      SIP::Locator[:PasswordStore] = SipperUtil::Persistence::CsvSipperMap.new("passwd_store")
      
      # Sipper HTTP Client
      SIP::Locator[:HttpRequestDispatcher] = SipperHttpRequestDispatcher.new(@q, SipperConfigurator[:HttpClientThreads])
      
      
      # Sipper HTTP Server
      if SipperConfigurator[:SipperHttpServer]
        
        require 'webrick'
        
        port = SipperConfigurator[:SipperHttpServerPort] 
        if SipperConfigurator[:SipperHttpServerConfig]
          port = SipperConfigurator[:SipperHttpServerConfig][:Port]
        end
        port = 2000 unless port
        config = SipperConfigurator[:SipperHttpServerConfig] || {}
        config[:Port] = port
        @w = WEBrick::HTTPServer.new(config)
        require 'sipper_http/sipper_http_servlet'
        @w.mount("/", SipperHttp::SipperHttpServlet)
      end
      #-------------------
      SIP::Locator[:Sipper] = self
      
      # NK
      Thread.abort_on_exception = true
        end
    
    
    
    
    def start
      if SipperConfigurator[:TestManagerName]
        if (Socket.gethostbyname(Socket.gethostname) == Socket.gethostbyname(SipperConfigurator[:TestManagerName]))
          DRb.start_service("druby://#{SipperConfigurator[:TestManagerName]}:#{SipperConfigurator[:TestManagerPort]}", SIP::TcshProxy.new)
        else
          DRb.start_service
        end
        @ilog.debug("Starting the client DRb service") if @ilog.debug?
      end
      @tm.start  # starting the timer manager
      
      
      # Timer helper
      SIP::Locator[:Sth] = SIP::SipTimerHelper.new(@tm)
      
      SIP::ControllerClassLoader.clear_all  # start from a clean slate
      if SipperConfigurator[:ControllerPath] && SipperConfigurator[:ControllerPath] != :file_given
        cdir = Dir.new(SipperConfigurator[:ControllerPath]) 
        SipperConfigurator[:ControllerLibPath] ||= File.join(SipperConfigurator[:ControllerPath], "lib")
        $:.unshift SipperConfigurator[:ControllerLibPath] # now transaction_handlers can be required in controllers
        Dir["#{SipperConfigurator[:ControllerLibPath]}/transport_filters/*.rb"].each{|x| load x } # load all filters
        Dir["#{SipperConfigurator[:ControllerLibPath]}/transport_filters/*.yaml"].each do |o|
          if o=~/in_order.yaml/
            ::Transport::BaseTransport.in_order = SipperUtil.load_yaml(o)
          elsif o=~/out_order.yaml/
            ::Transport::BaseTransport.out_order = SipperUtil.load_yaml(o)
          end
        end
        # Now loading the extensions
        Dir["#{SipperConfigurator[:ControllerLibPath]}/sipper_extensions/*.rb"].each{|x| require x }
      end
      SIP::Locator[:Cs] = SIP::ControllerSelector.new(cdir)
      t = Thread.new do
        SIP::Locator[:Tm].transports.each do |tr|
          tr.start_transport
          #@ilog.info("Started the transport #{tr}") if @ilog.info?
        end
        
        @smr.start       
        sleep(rand(1)) until @smr.running
        
        SIP::Locator[:Cs].get_controllers.each_with_index do |c, i|
          if c.class.start_on_load?
            Thread.new do
              Thread.current[:name] = "StarterThread-"+i.to_s
              @ilog.debug("Starting controller #{c.name}") if @ilog.debug?
              c.start  
            end
          end
        end
        @ilog.info("Sipper now started. Server version #{SIP::VERSION::STRING}") if @ilog.info?
        
        @smr.tg.list.each {|th| th.join} #law of demeter VVV
        
      end
      
      # now start the http client request dispatcher
	  sleep 1
      SIP::Locator[:HttpRequestDispatcher].start
      @running = true
      
      if SipperConfigurator[:GobletRelease] && SipperConfigurator[:RunGUI]
        require 'goblet/management/sipper_config_manager'
        @scm_server = Goblet::Management::SipperConfigManager.new.start
        # run the rails web server
        require File.dirname(__FILE__) + '../goblet/web/goblet_console/config/boot'
        #Thread.new do
        require 'commands/server'
        #end
      end
      
      if SipperConfigurator[:SipperHttpServer]
        Thread.new do
          @w.start  
        end
      end
      
      if x = SipperConfigurator[:SipperRunFor]
        Thread.new do
          sleep x
          exit
        end
      end
      
      return t
    end
    
    # Load a controller at runtime whose definition is given in the string.
    # eg. 
    #     str = <<-EOF
    #     require 'base_controller'
    #     module MyControllers
    #       class SimpleController < SIP::BaseController
    #         def start
    #           r = Request.create_initial("message", "sip:nasir@codepresso.com")
    #           u = create_udp_session("127.0.0.1", 5066)
    #           u.send(r)
    #         end
    #       end
    #     end
    #     EOF
    #     load_controller( str )
    # You would typically do this from within a test case or simple cases
    # where you do not need to define a controller in a specified controller
    # location. 
    def load_controller(str)
      _check_running
      SIP::Locator[:Cs].load_controller_from_string( str )
    end
    
    def start_controller(name)
      cs = SIP::Locator[:Cs].get_controller(name)
      if cs
        cs.start
      else
        raise ArgumentError, "Unknown controller #{name} cannot start"
      end
    end
    
    def start_named_controller(name)
      start_controller(name)
    end
    
    def start_controller_unless_sol(name)
      cs = SIP::Locator[:Cs].get_controller(name)
      if cs
        cs.start unless cs.class.start_on_load?
      else
        raise ArgumentError, "Unknown controller #{name} cannot start"
      end
    end
    
    
    def _check_running
      raise RuntimeError, "Sipper not running" unless @running
    end
    
    def reload_libs
      Dir[File.join(File.dirname(__FILE__), 'lib/**/*.rb')].each {|l| load l}
    end
    
    # todo have a nice stopping, graceful using shutdown hook
    def stop
      SIP::Locator[:Tm].transports.each do |t|
        t.stop_transport
        @ilog.info("Stopped the transport #{t}") if @ilog.info?
      end
      if SipperConfigurator[:SipperHttpServer]
        @w.shutdown if @w
      end  
      @smr.stop
      @ilog.info("Stopped the SIP Message Router") if @ilog.info?
      @tm.stop
      # stop the DRb server on this node
      DRb.stop_service
      
      # now stop the http client request dispatcher
      SIP::Locator[:HttpRequestDispatcher].stop
      
      @running = false
      SipperConfigurator[:ControllerLibPath] = nil  
      @q.clear
      @q = nil
      ::Transport::BaseTransport.clear_all_filters
      
      if SipperConfigurator[:GobletRelease]
        @scm_server.shutdown if @scm_server
      end
      if SipperConfigurator[:PrintHeapOnExit]
        a = Hash.new(0)
        ObjectSpace.each_object(Object) {|x| a[x.class.name] += 1}
        a.each {|k,v| puts "#{k}  #{v}" }
      end
    end
    
    def sipper_exit
      @exit_now = true
      exit
    end
    
    private :_check_running
  end
end
