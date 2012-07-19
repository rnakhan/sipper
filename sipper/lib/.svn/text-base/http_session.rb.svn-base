# webrick/session.rb -- Session manager like CGI::Session
# Lisence:: Ruby's

require 'digest/md5'
require 'tmpdir'
require 'webrick/cookie'

module WEBrick
  class Session
    public

    NoSession = Class.new(StandardError) unless defined? NoSession

    attr_reader(:session_id, :new_session)

    def self.callback(dbman)
      Proc.new do
        unless dbman.empty?
          dbman[0].close
        end
      end
    end

    def initialize(req, res, options = {})
      @new_session = false

      session_key = options['session_key'] || '_session_id'
      session_id = options['session_id']
      unless session_id
        if options['new_session']
          session_id = create_new_id
        end
      end
      unless session_id
        if req.query.key?(session_key)
          session_id = req.query[session_key]
          if session_id.respond_to?(:read)
            session_id = session_id.read
          end
        end
        unless session_id
          cookie = req.cookies.find do |ck|
            ck.name == session_key
          end
          if cookie
            session_id = cookie.value
          end
          unless session_id
            unless options.fetch('new_session', true)
              raise ArgumentError, "session_key `#{session_key}' should be supplied"
            end
            session_id = create_new_id
          end
        end
      end
      @session_id = session_id
      dbman = options['database_manager'] || FileStore
      begin
        @dbman = dbman.new(self, options)
      rescue NoSession
        unless options.fetch('new_session', true)
          raise ArgumentError, "Invalid session_id `#{session_id}'"
        end
        session_id = @session_id = create_new_id
        retry
      end
      unless options['no_hidden']
        @output_hidden = {session_key => session_id}
      end
      unless options['no_cookies']
        cookie = WEBrick::Cookie.new(session_key, session_id)
        cookie.expires = options['session_expires']
        cookie.domain = options['session_domain']
        cookie.secure = options['session_secure']
        cookie.path = if options['session_path']
                        options['session_path']
                      elsif ENV['SCRIPT_NAME']
                        File.dirname(ENV['SCRIPT_NAME'])
                      else
                        ''
                      end
        res.cookies.push(cookie)
      end
      @dbprot = [@dbman]
      ObjectSpace.define_finalizer(self, Session.callback(@dbprot))
    end

    def [](key)
      (@data ||= @dbman.restore)[key]
    end

    def []=(key, value)
      (@data ||= @dbman.restore)[key] = value
    end

    def update
      @dbman.update
    end

    def close
      @dbman.close
      @dbprot.clear
    end

    def delete
      @dbman.delete
      @dbprot.clear
    end

    private

    def create_new_id
      md5 = Digest::MD5.new
      now = Time.now
      md5.update(now.to_s)
      md5.update(String(now.usec))
      md5.update(String(rand(0)))
      md5.update(String($$))
      md5.update('foobar')
      @new_session = true
      md5.hexdigest[0,16]
    end

    public

    class FileStore
      def initialize(session, options = {})
        dir = options['tmpdir'] || Dir.tmpdir
        prefix = options['prefix'] || 'cgi_sid_'
        suffix = options['suffix'] || ''
        md5 = Digest::MD5.hexdigest(session.session_id)[0, 16]
        @path = File.join(dir, prefix + md5 + suffix)
        unless File.exist?(@path)
          unless session.new_session
            raise Session::NoSession, 'uninitialized session'
          end
          @hash = {}
        end
      end

      def restore
        unless @hash
          @hash = {}
          File.open(@path) do |f|
            f.flock(File::LOCK_SH)
            f.each_line do |line|
              line.chomp!
              key, value = line.split('=', 2)
              @hash[unescape(key)] = unescape(value)
            end
          end
        end
        @hash
      end

      def update
        return unless @hash
        File.open(@path, File::CREAT | File::TRUNC | File::RDWR, 0600) do |f|
          f.flock(File::LOCK_EX)
          @hash.each do |key, value|
            f.puts("#{escape(key)}=#{escape(String(value))}")
          end
        end
      end

      def close
        update
      end

      def delete
        begin
          File.unlink(@path)
        rescue Errno::ENOENT
        end
      end

      private

      def escape(str)
        str.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
          '%' + $1.unpack('H2' * $1.size).join('%').upcase
        end.tr(' ', '+')
      end

      def unescape(str)
        str.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
          [$1.delete('%')].pack('H*')
        end
      end
    end

    class MemoryStore
      @@global_hash_table = {}

      def initialize(session, options = nil)
        @session_id = session.session_id
        unless @@global_hash_table.key?(@session_id)
          unless session.new_session
            raise Session::NoSession, "uninitialized session"
          end
          @@global_hash_table[@session_id] = {}
        end
      end

      def restore
        @@global_hash_table[@session_id]
      end

      def update
      end

      def close
      end

      def delete
        @@global_hash_table.delete(@session_id)
      end
    end

    class NullStore
      def initialize(session, options = nil)
      end

      def restore
        {}
      end

      def update
      end

      def close
      end

      def delete
      end
    end
  end
end
