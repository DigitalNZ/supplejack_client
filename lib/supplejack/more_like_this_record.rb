# frozen_string_literal: true

require 'supplejack/request'

module Supplejack
  class MoreLikeThisRecord
    include Supplejack::Request

    attr_accessor :id, :params, :response

    def initialize(id, options = {})
      @id = id.to_i

      raise(Supplejack::MalformedRequest, "'#{id}' is not a valid record id") if @id <= 0

      @params = { frequency: options[:frequency] || 1 }
      @params[:mlt_fields] = options[:mlt_fields].join(',') unless options[:mlt_fields].blank?
    end

    # @return [ Array ] Array of Supplejack::Record objects
    #
    def records
      response = execute_request

      return [] unless response['records'].respond_to?(:map)

      response['records'].map do |attributes|
        Supplejack.record_klass.classify.constantize.new(attributes)
      end
    end

    def execute_request
      get("/records/#{@id}/more_like_this", @params)
    rescue RestClient::ResourceNotFound
      raise Supplejack::RecordNotFound, "Record with ID #{@id} was not found"
    rescue StandardError
      { 'records' => [] }
    end
  end
end
