# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe LogSubscriber do

    it 'returns nil when logging not enabled' do
      Supplejack.stub(:enable_logging) { false }

      Supplejack::LogSubscriber.new.log_request(1, {}).should be_nil
    end

  end
end
