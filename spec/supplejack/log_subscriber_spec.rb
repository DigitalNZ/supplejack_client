# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  describe LogSubscriber do
    it 'returns nil when logging not enabled' do
      allow(Supplejack).to receive(:enable_logging).and_return(false)

      expect(described_class.new.log_request(1, {})).to be nil
    end
  end
end
