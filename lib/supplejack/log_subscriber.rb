
module Supplejack
  class LogSubscriber < ActiveSupport::LogSubscriber

    # rubocop:disable Metrics/LineLength
    # FIXME: make line 24 (request = "") shorter
    def log_request(duration, payload, solr_request_params={})
      return unless Supplejack.enable_debugging

      solr_request_params ||= {}
      payload ||= {}
      payload.reverse_merge!({:params => {}, :options => {}, :payload => {}})
      method = payload[:method] || :get

      name = '%s (%.1fms)' % ["Supplejack API #{Rails.env}", duration]

      parameters = payload[:params].map { |k, v| "#{k}: #{colorize(v, BOLD)}" }.join(', ')
      body = payload[:payload].map { |k, v| "#{k}: #{colorize(v, BOLD)}" }.join(', ')
      options = payload[:options].map { |k, v| "#{k}: #{colorize(v, BOLD)}" }.join(', ')
      request = "#{method.to_s.upcase} path=#{payload[:path]} params={#{parameters}}, body={#{body}} options={#{options}}"

      if payload[:exception]
        info = "\n  #{colorize('Exception', RED)} [ #{payload[:exception].join(', ')} ]"
      else
        info = ""
        if solr_request_params.try(:any?)
          solr_request_params = solr_request_params.map { |k, v| "#{k}: #{colorize(v, BOLD)}" }.join(', ')
          info = "\n  #{colorize('SOLR Request', YELLOW)} [ #{solr_request_params} ]"
        end
      end

      debug "  #{colorize(name, GREEN)}  [ #{request} ] #{info}"
    end

    def colorize(text, color)
      if text.is_a?(Hash)
        "{#{text.map {|k, v| "#{k}: #{colorize(v, color)}" }.join(', ')}}"
      elsif text.is_a?(Array)
        "[#{text.map {|e| colorize(e, color) }.join(', ')}]"
      else
        "#{BOLD}#{color}#{text}#{CLEAR}"
      end
    end

  end
end
