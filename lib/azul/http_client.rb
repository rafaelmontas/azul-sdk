# frozen_string_literal: true

module Azul
  class HttpClient
    def initialize
      @config = Azul.configuration
      @url_builder = UrlBuilder.new(@config.environment)
    end

    def post(params = {}, action: nil)
      required_params = { "Channel": "EC", "PosInputMode": "E-Commerce", "Store": @config.merchant_id }
      api_url = @url_builder.build(action: action)

      perform_request(:post, api_url, params.merge(required_params))
    end

    private

    def perform_request(method, api_url, params)
      uri = URI(api_url)
      http = create_http_client(uri)
      net_request = build_net_request(method, uri, params)

      request = build_request_object(method, api_url, net_request, params)
      response = http.request(net_request)

      Response.new(response, request)
    end

    def create_http_client(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.ssl_timeout = @config.timeout
      http.open_timeout = @config.timeout
      http.read_timeout = @config.timeout
      http.write_timeout = @config.timeout

      # Configure SSL
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.cert = OpenSSL::X509::Certificate.new(@config.client_certificate)
      http.key = OpenSSL::PKey::RSA.new(@config.client_key)

      http
    end

    def build_net_request(method, uri, params)
      case method
      when :get
        Net::HTTP::Get.new(uri.request_uri)
      when :post
        req = Net::HTTP::Post.new(uri.request_uri)
        req.body = params.to_json
        req
      end.tap { |req| add_headers(req) }
    end

    def add_headers(request)
      request["Auth1"] = @config.auth_1
      request["Auth2"] = @config.auth_2
      request["Content-Type"] = "application/json"
    end

    def build_request_object(method, api_url, net_request, params)
      headers = {}
      net_request.each_header { |k, v| headers[k] = v }
      Request.new(method, api_url, headers, params)
    end
  end
end
