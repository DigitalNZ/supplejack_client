# frozen_string_literal: true

require 'rest-client'

module Supplejack
  module Request
    extend ActiveSupport::Concern

    def get(path, params = {}, options = {})
      tries ||= 5
      params ||= {}

      url = full_url(path, options[:format], params)

      started = Time.now
      payload = { path: path, params: params, options: options }

      begin
        result = RestClient::Request.execute(url: url, method: :get, read_timeout: timeout(options))
        result = JSON.parse(result) if result
      rescue RestClient::ServiceUnavailable => e
        retry unless (tries -= 1).zero?
        raise e
      rescue StandardError => e
        payload[:exception] = [e.class.name, e.message]
        raise e
      ensure
        duration = (Time.now - started) * 1000 # Convert to milliseconds
        solr_request_params = result['search']['solr_request_params'] if result.is_a?(Hash) && result['search']
        @subscriber = Supplejack::LogSubscriber.new
        @subscriber.log_request(duration, payload, solr_request_params)
      end

      result
    end

    def post(path, params = {}, payload = {}, options = {})
      payload ||= {}
      log_request(:post, path, params, payload) do
        response = begin
                    RestClient::Request.execute(url: full_url(path, nil, params),
                                                              method: :post, payload: payload.to_json,
                                                              timeout: timeout(options),
                                                              headers: { content_type: :json, accept: :json })
                  rescue RestClient::ExceptionWithResponse => e
                    e.response.body
                  end
        begin
          JSON.parse(response)
        rescue StandardError
          {}.to_json
        end
      end
    end

    def delete(path, params = {}, options = {})
      log_request(:delete, path, params, {}) do
        RestClient::Request.execute(url: full_url(path, nil, params),
                                    method: :delete,
                                    timeout: timeout(options))
      end
    end

    def put(path, params = {}, payload = {}, options = {})
      payload ||= {}
      log_request(:put, path, params, payload) do


        response = begin 
                    RestClient::Request.execute(url: full_url(path, nil, params),
                                                method: :put,
                                                payload: payload.to_json,
                                                timeout: timeout(options),
                                                headers: { content_type: :json, accept: :json })
                  rescue RestClient::ExceptionWithResponse => e
                    e.response.body
                  end

        begin
          JSON.parse(response)
        rescue StandardError
          {}.to_json
        end
      end
    end

    def patch(path, params = {}, payload = {}, options = {})
      payload ||= {}
      log_request(:patch, path, params, payload) do
        response = begin
                    RestClient::Request.execute(url: full_url(path, nil, params),
                                                          method: :patch,
                                                          payload: payload.to_json,
                                                          timeout: timeout(options),
                                                          headers: { content_type: :json, accept: :json })
                  rescue RestClient::ExceptionWithResponse => e

                    binding.pry

                    e.response.body
                  end

        begin
          JSON.parse(response)
        rescue StandardError
          {}.to_json
        end
      end
    end

    private

    def full_url(path, format = nil, params = {})
      params ||= {}
      params[:api_key] ||= Supplejack.api_key
      params[:debug] = true if Supplejack.enable_debugging

      "#{Supplejack.api_url}#{path}.#{format || 'json'}?#{params.to_query}"
    end

    # Found ou that RestClient timeouts are not reliable. Setting a 30 sec
    # timeout is taking about 60 seconds re raise timeout error. So now the
    # default value is 15
    def timeout(options = {})
      timeout = Supplejack.timeout.to_i.zero? ? 15 : Supplejack.timeout.to_i
      options[:timeout] || timeout
    end

    def log_request(method, path, params = {}, payload = {})
      information = { path: path }
      information[:params] = params
      information[:payload] = payload
      information[:method] = method

      begin
        started = Time.now
        yield
      rescue StandardError => e
        information[:exception] = [e.class.name, e.message]
        raise e
      ensure
        duration = (Time.now - started) * 1000 # Convert to miliseconds
        @subscriber = Supplejack::LogSubscriber.new
        @subscriber.log_request(duration, information, {})
      end
    end
  end
end
