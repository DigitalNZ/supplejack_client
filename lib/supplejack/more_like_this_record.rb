# frozen_string_literal: true

require 'supplejack/request'

module Supplejack
  class MoreLikeThisRecord
    include Supplejack::Request

    DEFAULT_OPTIONS = { frequency: 1 }.freeze

    attr_accessor :id, :params, :response

    def initialize(id, options = {})
      @id = id.to_i

      raise(Supplejack::MalformedRequest, "'#{id}' is not a valid record id") if @id <= 0

      @params = options&.reverse_merge(DEFAULT_OPTIONS) || DEFAULT_OPTIONS
      @params[:mlt_fields] = @params[:mlt_fields].join(',') if @params[:mlt_fields]
    end

    # @return [ Array ] Array of Supplejack::Record objects
    #
    def records
      response = execute_request

      return [] unless response['more_like_this']['results'].respond_to?(:map)

      response['more_like_this']['results'].map do |attributes|
        Supplejack.record_klass.classify.constantize.new(attributes)
      end
    end

    def execute_request
      get("/records/#{@id}/more_like_this", @params)
    rescue RestClient::ResourceNotFound
      raise Supplejack::RecordNotFound, "Record with ID #{@id} was not found"
    rescue StandardError
      { 'more_like_this' => { 'results' => [] } }
    end
  end
end
