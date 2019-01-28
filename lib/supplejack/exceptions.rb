# frozen_string_literal: true

module Supplejack
  class RecordNotFound < StandardError; end

  class ConceptNotFound < StandardError; end

  class SetNotFound < StandardError; end

  class StoryNotFound < StandardError; end

  class StoryUnauthorised < StandardError; end

  class MalformedRequest < StandardError; end

  class RequestTimeout < StandardError; end

  class ApiNotAvailable < StandardError; end
end
