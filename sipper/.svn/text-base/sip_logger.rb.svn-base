require 'log4r'
require 'log4r/configurator'
require 'modified_pattern_formatter'
require 'sipper_configurator'
require 'bin/common'

module SipLogger
  include Log4r
  SipperUtil::Common.set_environment()
  Configurator['logpath'] = SipperConfigurator[:LogPath]||(SipperConfigurator[:LogPath]= File.join(File.dirname(__FILE__), "logs"))
  Configurator['pid'] = Process.pid.to_s
  Configurator['udfname'] = $ULOGNAME || ""
  if SipperConfigurator[:ConfigPath]
    Configurator.load_xml_file File.join(SipperConfigurator[:ConfigPath],"log4r.xml")
  else
    Configurator.load_xml_file File.join(File.dirname(__FILE__), "config", "log4r.xml")  
  end
  
  @@class_named_loggers = {}  #configured loggers only
  
  Logger.each_logger do |logger|
    @@class_named_loggers[logger.name] = logger 
  end
   
  # look up logger by full name eg. siplog::request
  def SipLogger.[](arg)
    Logger[arg]
  end
  
  def SipLogger.each &block
    Logger.each_logger(&block)
  end
  
  # gets the class named logger
  def logger
    @@class_named_loggers[self.class_name.downcase]
  end
  
  # the log methods
  def logd(arg)
    logger.debug(arg) if logger.debug?  
  end
  
  def logi(arg)
    logger.info(arg) if logger.info?  
  end
  
  def logw(arg)
    logger.warn(arg) if logger.warn?  
  end
  
  def loge(arg)
    logger.error(arg) if logger.error?  
  end
  
  def logf(arg)
    logger.fatal(arg) if logger.fatal?  
  end
  
  @@msgTrace = SipLogger['sipmsgtracelog']

  # Direction I/O (incoming/outgoing), remore ip, remote port, message
  def logsip(direction, rip, rp, lip, lp, tp, msg)
    @@msgTrace.debug("\nremote #{rip}:#{rp}\nlocal #{lip}:#{lp} #{tp}\n----------#{direction}----------\n#{msg}\n---------------------\n") if @@msgTrace.debug?
  end
  
  
end
