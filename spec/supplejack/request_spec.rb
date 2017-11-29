# The Supplejack Common code is
# Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the
# National Library of NZ and the Department of Internal Affairs.
# http://digitalnz.org/supplejack

require 'spec_helper'

class Test
  include Supplejack::Request
end

module Supplejack
  describe Request do
    before(:each) do
      @test = Test.new
      Supplejack.stub(:api_key) { '123' }
      Supplejack.stub(:api_url) { 'http://api.org' }
      Supplejack.stub(:timeout) { 20 }
    end

    describe '#get' do
      before(:each) do
        RestClient::Request.stub(:execute).and_return(%{ {"search": {}} })
      end

      it 'serializes the parameters in the url' do
        RestClient::Request.should_receive(:execute).with(hash_including(:url => "http://api.org/records.json?#{{:and => {:name => 'John'}}.to_query}&api_key=123"))
        @test.get('/records', {:and => {:name => 'John'}})
      end

      it 'parses the JSON returned' do
        RestClient::Request.stub(:execute).and_return(%{ {"search": {}} })
        @test.get('/records').should eq({'search' => {}})
      end

      it 'logs a error correctly when the response from the API failed' do
        RestClient::Request.stub(:execute).and_return(nil)
        @subscriber = Supplejack::LogSubscriber.new
        Supplejack::LogSubscriber.stub(:new) { @subscriber }
        @subscriber.should_receive(:log_request)
        @test.get('/records')
      end

      context 'request format' do
        it 'executes a request in a json format' do
          RestClient::Request.should_receive(:execute).with(hash_including(:url => 'http://api.org/records.json?api_key=123'))
          @test.get('/records')
        end

        it 'overrides the response format with xml' do
          RestClient::Request.should_receive(:execute).with(hash_including(:url => 'http://api.org/records.xml?api_key=123'))
          @test.get('/records', {}, {:format => :xml})
        end
      end

      context 'api key' do
        it 'overrides the api key' do
          RestClient::Request.should_receive(:execute).with(hash_including(:url => 'http://api.org/records.json?api_key=456'))
          @test.get('/records', {:api_key => '456'})
        end
      end

      context 'timeout' do
        it 'calculates the timeout' do
          @test.should_receive(:timeout).with(hash_including({:timeout => 60}))
          @test.get('/', {}, {:timeout => 60})
        end
      end

      context 'restlclient unavailable' do
        it 'retries request 5 times' do
          RestClient::Request.stub(:execute).and_raise(RestClient::ServiceUnavailable)
          RestClient::Request.should_receive(:execute).exactly(5).times
          expect {
            @test.get('/records')
            }.to raise_error(RestClient::ServiceUnavailable)
        end
      end

    end

    describe '#post' do
      before(:each) do
        RestClient::Request.stub(:execute)
      end

      it 'executes a post request' do
        RestClient::Request.should_receive(:execute).with(hash_including(:method => :post))
        @test.post('/records/1/ucm', {})
      end

      it 'passes the payload along' do
        payload = {'ucm_record' => {:name => 'geocords', :value => '1234'}}
        RestClient::Request.should_receive(:execute).with(hash_including(:payload => payload.to_json))
        @test.post('/records/1/ucm', {}, payload)
      end

      it 'adds the extra parameters to the post request' do
        @test.should_receive(:full_url).with('/records/1/ucm', nil, {api_key: '12344'})
        @test.post('/records/1/ucm', {api_key: '12344'}, {})
      end

      it 'adds json headers and converts the payload into json' do
        RestClient::Request.should_receive(:execute).with(hash_including(:headers => {:content_type => :json, :accept => :json}, :payload => {records: [{record_id: 1, position: 1}, {record_id:2, position:2}]}.to_json))
        @test.post('/records/1/ucm', {}, {records: [{record_id: 1, position: 1}, {record_id:2, position:2}]})
      end

      it 'parses the JSON response' do
        RestClient::Request.stub(:execute) { {user: {name: 'John'}}.to_json }
        @test.post('/users', {}, {}).should eq({'user' => {'name' => 'John'}})
      end
    end

    describe '#delete' do
      before(:each) do
        RestClient::Request.stub(:execute)
      end

      it 'executes a delete request' do
        RestClient::Request.should_receive(:execute).with(hash_including(:method => :delete))
        @test.delete('/records/1/ucm/1')
      end

      it 'adds the extra parameters to the delete request' do
        @test.should_receive(:full_url).with('/records/1/ucm/1', nil, {api_key: '12344'})
        @test.delete('/records/1/ucm/1', {api_key: '12344'})
      end
    end

    describe '#put' do
      before(:each) do
        RestClient::Request.stub(:execute)
      end

      it 'executes a put request' do
        RestClient::Request.should_receive(:execute).with(hash_including(:method => :put))
        @test.put('/records/1/ucm/1')
      end

      it 'passes the payload along' do
        RestClient::Request.should_receive(:execute).with(hash_including(:payload => {:name => 1}.to_json))
        @test.put('/records/1/ucm/1', {}, {:name => 1})
      end

      it 'adds the extra parameters to the put request' do
        @test.should_receive(:full_url).with('/records/1/ucm/1', nil, {api_key: '12344'})
        @test.put('/records/1/ucm/1', {api_key: '12344'}, {})
      end

      it 'adds json headers and converts the payload into json' do
        RestClient::Request.should_receive(:execute).with(hash_including(:headers => {:content_type => :json, :accept => :json}, :payload => {records: [1,2,3]}.to_json))
        @test.put('/records/1/ucm/1', {}, {records: [1,2,3]})
      end

      it 'parses the JSON response' do
        RestClient::Request.stub(:execute) { {user: {name: 'John'}}.to_json }
        @test.put('/users/1', {}, {}).should eq({'user' => {'name' => 'John'}})
      end
    end

    describe '#timeout' do
      it 'defaults to the timeout in the configuration' do
        @test.send(:timeout).should eq 20
      end

      it 'defaults to 30 when not set in the configuration' do
        Supplejack.stub(:timeout) { nil }
        @test.send(:timeout).should eq 30
      end

      it 'overrides the timeout' do
        @test.send(:timeout, {:timeout => 60}).should eq 60
      end
    end

    describe '#full_url' do
      it 'returns the full url with default api_url, format and api_key' do
        @test.send(:full_url, '/records').should eq('http://api.org/records.json?api_key=123')
      end

      it 'overrides the format' do
        @test.send(:full_url, '/records', 'xml').should eq('http://api.org/records.xml?api_key=123')
      end

      it 'overrides the api key' do
        @test.send(:full_url, '/records', nil, {:api_key => '456'}).should eq('http://api.org/records.json?api_key=456')
      end

      it 'url encodes the parameters' do
        @test.send(:full_url, '/records', nil, {:api_key => '456', :i => {:category => 'Images'}}).should eq('http://api.org/records.json?api_key=456&i%5Bcategory%5D=Images')
      end

      it 'adds debug=true when enable_debugging is set to true' do
        Supplejack.stub(:enable_debugging) { true }
        @test.send(:full_url, '/records', nil, {}).should eq 'http://api.org/records.json?api_key=123&debug=true'
      end

      it 'handles nil params' do
        @test.send(:full_url, '/records', nil, nil).should eq 'http://api.org/records.json?api_key=123'
      end
    end

  end
end
