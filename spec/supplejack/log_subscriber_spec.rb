require 'spec_helper'

module Supplejack
  describe LogSubscriber do

    it 'returns nil when logging not enabled' do
      Supplejack.stub(:enable_logging) { false }

      Supplejack::LogSubscriber.new.log_request(1, {}).should be_nil
    end

  end
end
