$:.unshift File.join(File.dirname(__FILE__),"..","sipper")

require 'transport/udp_transport'
require 'test/unit'
require 'tracing'
class TestUdpTransport < Test::Unit::TestCase
  
  #include Tracing
  def setup
    @ip = SipperConfigurator[:LocalSipperIP]
    @port = 5062
    @t1 = Transport::UdpTransport.instance(@ip, @port)
  end
  
  def test_instance
    assert_raise(NoMethodError){Transport::UdpTransport.new}
    t2 = Transport::UdpTransport.instance(@ip, @port)
    _check_equal(t2)
    @t1 = Transport::UdpTransport.instance(@ip, @port)
    _check_equal(t2)
    t3 = Transport::UdpTransport.instance(@ip, @port+1)
    assert_not_equal(@t1, t3)
    assert(!t2.equal?(t3))
  end
  
  
  
  def test_running
    assert(!@t1.running)
    @t1.start_transport
    assert(@t1.running)
    assert_raise(RuntimeError) {@t1.start_transport}
  end
  
  def test_stopping
    test_running
    @t1.stop_transport
    assert(!@t1.running)
    assert_raise(RuntimeError) {@t1.stop_transport}
  end
  
  def test_transport_thread
    th = @t1.start_transport
    assert(th.alive?)
    @t1.stop_transport
    assert(th.stop?)
  end
  

  def test_recv
    th = @t1.start_transport
    sleep(rand(1)) until @t1.running
    s1 = UDPSocket.new
    s1.connect(@ip, @port)
    s1.send "hello_recv" , 0
    data = @t1.get_next_message
    assert_equal("hello_recv", data[0])
    assert(th.alive?)
    s1.send "poison dart" , 0
    data = @t1.get_next_message
    assert_equal("poison dart", data[0])
    th.join
    assert(th.stop?)
  end

  
  def _send s_msg, r_msg
    th2 = Thread.new do 
      s = UDPSocket.new
      s.bind(@ip, @port+1)
      IO.select([s])
      x = s.recvfrom_nonblock(100)[0]
      assert_equal(x, r_msg)
      s.close
    end
    @t1.send(s_msg, 0, @ip, @port+1)
    th2.join
  end
  
  def test_send
    test_running
    _send "hello_nasir", "hello_nasir"
  end
  
  def test_one_start
    started = []
    threads = [] 
    50.times do
      threads << Thread.new do
        sleep(rand(3))
        begin
          @t1.start_transport
          started << 1
          rescue RuntimeError
            started << 0 
        end #exception
      end  #threads
    end #50
    threads.each {|t| t.join}
    assert_equal(1, started.inject {|s,v| s = s+v} )
  end
  
  def teardown
   @t1.stop_transport if @t1.running
  end
  
  
  def _check_equal(t2)
    assert_equal(@t1, t2)
    assert(@t1.equal?(t2))
  end
  
  private :_check_equal, :_send
  
end