
module Supplejack
  class RecordNotFound < StandardError; end

  class ConceptNotFound < StandardError; end

  class SetNotFound < StandardError; end

  class StoryNotFound < StandardError; end

  class StoryUnauthorised < StandardError; end

  class MalformedRequest < StandardError; end
end
