# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe LogSubscriber do
    
    it 'returns nil when logging not enabled' do
      Supplejack.stub(:enable_logging) { false }
      Supplejack::LogSubscriber.new.log_request(1, {}).should be_nil
    end
    
    describe '#api_environment' do
      it 'returns Prod' do
        Supplejack.stub(:api_url) { 'http://api.digitalnz.org' }
        Supplejack::LogSubscriber.new.api_environment.should eq 'Prod'
      end
      
      it 'returns Staging' do
        Supplejack.stub(:api_url) { 'http://hippo.uat.digitalnz.org:8001' }
        Supplejack::LogSubscriber.new.api_environment.should eq 'Staging'
      end
      
      it 'returns Staging' do
        Supplejack.stub(:api_url) { 'http://api.uat.digitalnz.org' }
        Supplejack::LogSubscriber.new.api_environment.should eq 'Staging'
      end
      
      it 'returns Dev' do
        Supplejack.stub(:api_url) { 'http://localhost:3000' }
        Supplejack::LogSubscriber.new.api_environment.should eq 'Dev'
      end
    end
  end
end
