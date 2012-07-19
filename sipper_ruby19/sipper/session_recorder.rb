require 'yaml'
require 'sipper_configurator'
require 'message'

# Recording of a session happens, either when you have 
# the global setting for recording :SessionRecord= true or you
# get the P header P-Session-Record, the values for the global
# var or the header can be "msg-info" or "msg-debug"  
# msg-info just records the in-out messages and msg-debug records 
# full SIP messages.
# 

require 'sip_logger'
require 'stringio'
require 'monitor'

class SessionRecorder
  include SipLogger
  
  attr_accessor :level
  
  private_class_method :new
  
  @@count = 0
  @@val = 0
  @@base = 0
  @@class_lock = Monitor.new
  
  def SessionRecorder.get_new_count
    @@class_lock.synchronize do
      @@count += 1
      if @@count == 10
        @@count = 0
        @@base = @@val*10
      end
      @@val = @@base + @@count
      if SipperConfigurator[:RunLoad]
        if @@val > 99999999999999999999999999
          @@count = 0
          @@base = 0
          @@val = 0
        end
      end
    end
    @@val
  end
  
  def SessionRecorder.create_and_record(io, msg, msg_s, direction, session_setting=nil, emit_console=false)
    if (msg.respond_to?:p_session_record)
      level = msg.p_session_record.to_s
    elsif session_setting
      level = session_setting
    else
      level = SipperConfigurator[:SessionRecord]
    end
    if level
      if io
        sr = new(nil, io, level) 
      else
        sr = new(SessionRecorder.get_new_count.to_s+"-"+msg.call_id.to_s+"_"+direction , nil, level) 
      end 
    end
    sr.record(direction, msg, msg_s, emit_console) if sr
    return sr
  end
  
  
  def initialize(f, io, l="msg-info")
    @ilog = logger
    @messages = []
    @io = io
    @level = l
    path = SipperConfigurator[:SessionRecordPath]||SipperConfigurator[:LogPath]
    @filename = File.join(path, f)  if f
    @recordable = true
  end
  
  def io=(io)
    ensure_recordable
    @io.close if @io
    @io = io  
  end
  
  def open_file_if_unopened
    return if @io
    io = File.new(@filename, "w+")
    io.flock(File::LOCK_EX)  if SipperConfigurator[:EnableRecordingLock]
    self.io = io
  end
  
  # Record takes both sip message and also the optional string representation of 
  # the message as the message is filled as we go along the stack and populate the 
  # message. The string representation is the final string that goes out from the 
  # transport. 
  
  def record(direction, msg, msg_s=nil, emit_console=false )
    ensure_recordable
    open_file_if_unopened
    case @level
    when "msg-info"
      if msg.class == Request
        m = msg.method  
      elsif msg.class == Response
        m = msg.code.to_s
      else
        m = msg.to_s
      end
    when "msg-debug"
      m = msg_s.nil? ? msg.to_s : msg_s
    else
      m = "Unknown_record_level #{@level}, I know only msg-info and msg-debug"
    end
    if direction == "in"
      m = "< " + m
    elsif  direction == "out"
      m = "> " + m
    elsif direction == "neutral"
      m = "! " + m
    else
      m = "UNKNOWN DIRECTION " + m
    end
    print "#{m}  " if emit_console
    @messages << m
  end 
  
  def get_recording
    @messages
  end
  
  def get_info_only_recording
    return @messages if @level == "msg-info"
    @messages.map do |msg|
      prefix = msg[0..1]
      message = msg[2..-1]
      unless prefix == "! "  #neutral
        begin
          m = Message.parse([message, ["AF_INET", 33302, "localhost.localdomain", "127.0.0.1"]])
          if m.class == Request
            prefix + m.method  
          elsif m.class == Response
            prefix + m.code.to_s
          end
        rescue ArgumentError
          msg
        end
      else
        msg  
      end
    end
  end
  
  
  def save
    ensure_recordable
    @ilog.debug("Trying to save the recording in #{@io.path||@io}") if @ilog.debug?
    @recordable = false
    begin
      @io.write(YAML::dump(self)) 
      @io.flush
    ensure
      @io.flock(File::LOCK_UN) if @io.class == File if SipperConfigurator[:EnableRecordingLock]
      @io.close unless @io.class == StringIO
    end
    @ilog.debug("Saved the recording in #{@io.path||@io}") if @ilog.debug?
  end
  
  @@slog = SipLogger['siplog::sessionrecorder']
  
  def SessionRecorder.load(f)
    @@slog.debug("Reading the recording from #{f}") if @@slog.debug?
    begin
      case f
      when String
        io = File.new(f, "r")
        io.flock(File::LOCK_EX) if SipperConfigurator[:EnableRecordingLock]
      when StringIO
        io = f   
      end
	  YAML::ENGINE.yamler = 'syck'
      obj = YAML::load(io)
      if obj.class == SessionRecorder
        return obj
      else
        msg = "Object read from file #{f} is not a recording"
        @@slog.error(msg) if @@slog.error?
        raise TypeError, msg
      end
    rescue IOError
      msg = "#{f} is not a proper file"
      @@slog.error(msg) if @@slog.error?
      raise TypeError, msg
    ensure
      io.flock(File::LOCK_UN) if io.class == File if SipperConfigurator[:EnableRecordingLock]
      io.close  if io  
    end
  end
  
  def ensure_recordable
    raise RuntimeError, "This recorder is now closed for recording" unless @recordable
  end
  
  private :open_file_if_unopened, :ensure_recordable
end
