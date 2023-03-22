# frozen_string_literal: true

module Supplejack
  class ModerationRecord
    attr_reader :id, :created_at, :updated_at, :state, :user

    def initialize(id:, created_at:, updated_at:, user:, state:)
      @id = id
      @created_at = Util.time(created_at)
      @updated_at = Util.time(updated_at)
      @user = User.new(user)
      @state = state
    end
  end
end
