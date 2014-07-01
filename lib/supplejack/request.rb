# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'rest-client'

module Supplejack
	module Request
		extend ActiveSupport::Concern

		def get(path, params={}, options={})
      params ||= {}
      url = full_url(path, options[:format], params)

      started = Time.now
      payload = {:path => path, :params => params, :options => options}

      begin
        result = RestClient::Request.execute(:url => url, :method => :get, :timeout => timeout(options))
        result = JSON.parse(result) if result
      rescue StandardError => e
        payload[:exception] = [e.class.name, e.message]
        raise e
      ensure
        duration = (Time.now - started)*1000 # Convert to miliseconds
        solr_request_params = result["search"]['solr_request_params'] if result && result['search']
        @subscriber = Supplejack::LogSubscriber.new
        @subscriber.log_request(duration, payload, solr_request_params)
      end

      result
    end

    def post(path, params={}, payload={}, options={})
      payload ||= {}
      log_request(:post, path, params, payload) do
        response = RestClient::Request.execute(:url => full_url(path, nil, params), :method => :post, :payload => payload.to_json, :timeout => timeout(options), :headers => {:content_type => :json, :accept => :json})
        JSON.parse(response) rescue {}.to_json
      end
    end

    def delete(path, params={}, options={})
      log_request(:delete, path, params, {}) do
        RestClient::Request.execute(:url => full_url(path, nil, params), :method => :delete, :timeout => timeout(options))
      end
    end

    def put(path, params={}, payload={}, options={})
      payload ||= {}
      log_request(:put, path, params, payload) do
        response = RestClient::Request.execute(:url => full_url(path, nil, params), :method => :put, :payload => payload.to_json, :timeout => timeout(options), :headers => {:content_type => :json, :accept => :json})
        JSON.parse(response) rescue {}.to_json
      end
    end

    private

    def full_url(path, format=nil, params={})
      params ||= {}
      format = format ? format : 'json'
      params[:api_key] ||= Supplejack.api_key
      params[:debug] = true if Supplejack.enable_debugging

      Supplejack.api_url + path + ".#{format.to_s}" + '?' + params.to_query
    end

    def timeout(options={})
      timeout = Supplejack.timeout.to_i == 0 ? 30 : Supplejack.timeout.to_i
      options[:timeout] || timeout
    end

    def log_request(method, path, params={}, payload={})
      information = {path: path}
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
        duration = (Time.now - started)*1000 # Convert to miliseconds
        @subscriber = Supplejack::LogSubscriber.new
        @subscriber.log_request(duration, information, {})
      end
    end

	end	
end
