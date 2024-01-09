# frozen_string_literal: true

module Supplejack
  class LogSubscriber < ActiveSupport::LogSubscriber
    def log_request(duration, payload, solr_request_params = {})
      return unless Supplejack.enable_debugging

      solr_request_params ||= {}
      payload ||= {}
      payload.reverse_merge!(params: {}, options: {}, payload: {})
      method = payload[:method] || :get

      name = format('%s (%.1fms)', "Supplejack API #{Rails.env}", duration)

      parameters = payload[:params].map { |k, v| "#{k}: #{colorize(v, MODES[:bold])}" }.join(', ')
      body = payload[:payload].map { |k, v| "#{k}: #{colorize(v, MODES[:bold])}" }.join(', ')
      options = payload[:options].map { |k, v| "#{k}: #{colorize(v, MODES[:bold])}" }.join(', ')
      request = "#{method.to_s.upcase} path=#{payload[:path]} params={#{parameters}}, body={#{body}} options={#{options}}"

      if payload[:exception]
        info = "\n  #{colorize('Exception', RED)} [ #{payload[:exception].join(', ')} ]"
      else
        info = ''
        if solr_request_params.try(:any?)
          solr_request_params = solr_request_params.map { |k, v| "#{k}: #{colorize(v, MODES[:bold])}" }.join(', ')
          info = "\n  #{colorize('SOLR Request', YELLOW)} [ #{solr_request_params} ]"
        end
      end

      debug "  #{colorize(name, GREEN)}  [ #{request} ] #{info}"
    end

    def colorize(text, color)
      case text
      when Array then "[#{text.map { |e| colorize(e, color) }.join(', ')}]"
      when Hash then "{#{text.map { |k, v| "#{k}: #{colorize(v, color)}" }.join(', ')}}"
      else
        "#{MODES[:bold]}#{color}#{text}#{MODES[:clear]}"
      end
    end
  end
end
