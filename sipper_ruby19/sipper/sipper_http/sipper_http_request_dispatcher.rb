require 'net/http'
require 'thread'
require 'uri'
require 'sipper_http/sipper_http_response'
require 'sip_logger'

class HttpUrlContext
  attr_accessor :url, :session, :params, :req_method, :user, :passwd, :hdr_arr, :body
  def initialize(url, req_method, session, params, user, passwd, hdr_arr, body)
    @url = url
    @session = session
    @params = params
    @req_method = req_method
    @user = user
    @passwd = passwd
    @hdr_arr = hdr_arr
    @body = body
  end
end


class SipperHttpRequestDispatcher
  include SipLogger
  # sipper_message_queue is the main event queue in sipper 
  # this is where all the sip/timer/media and now http responses
  # are queued.
  def initialize(sipper_msg_queue, num_threads = 5)
    @ilog = logger
    @num_threads = num_threads
    @request_queue = Queue.new 
    @run = false
    @smq = sipper_msg_queue
  end
  
  def start
    @run = true
    1.upto(@num_threads) do |i|
      Thread.new do
        Thread.current[:name] = "HttpClientThread-"+i.to_s
        while @run
          url_context = @request_queue.pop
          return unless @run
          url = URI.parse(url_context.url)
          res = nil
          if url_context.req_method == 'get'
            req = Net::HTTP::Get.new(url.request_uri)
          elsif url_context.req_method == 'put'
            req = Net::HTTP::Put.new(url.path)
          elsif url_context.req_method == 'post'
            req = Net::HTTP::Post.new(url.path)
          else
            raise "Unsupported HTTP method #{url_context.req_method}"
          end
          req.basic_auth(url_context.user, url_context.passwd) if url_context.user && url_context.passwd
          if url_context.hdr_arr && url_context.hdr_arr.size > 0 
            url_context.hdr_arr.each do |k, v|
              req[k] = v
            end
          end           
          req.set_form_data( url_context.params, '&') if url_context.params
          req.body = url_context.body if url_context.body
          logsip("O", url.host, url.port, nil, nil, "HTTP", req.to_s)
          res = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }                   
          logsip("I", url.host, url.port, nil, nil, "HTTP", res.to_s)
          sipper_res = SipperHttp::SipperHttpResponse.new(res, url_context.session)
          @smq << sipper_res
        end  
      end
    end  
  end
  
  def stop
    @run = false
    @request_queue.clear
    @request_queue = nil
  end
  
  # params are a hash of POST parameters
  def request_post(url, session, params, user, passwd, hdr_arr, body)
    @ilog.debug('POST request called on dispatcher, now enquing request') if @ilog.debug?
    @request_queue << HttpUrlContext.new(url, 'post', session, params, user, passwd, hdr_arr, body)  
  end
  
  def request_put(url, session, user, passwd, hdr_arr, body)
    @ilog.debug('PUT request called on dispatcher, now enquing request') if @ilog.debug?
    @request_queue << HttpUrlContext.new(url, 'put', session, nil, user, passwd, hdr_arr, body)
  end
  
  def request_get(url, session, user, passwd, hdr_arr, body)
    @ilog.debug('GET request called on dispatcher, now enquing request') if @ilog.debug?
    @request_queue << HttpUrlContext.new(url, 'get', session, nil, user, passwd, hdr_arr, body)
  end
  
end
