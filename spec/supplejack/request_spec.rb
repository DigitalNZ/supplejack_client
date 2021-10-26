# frozen_string_literal: true

require 'spec_helper'

module Supplejack
  class TestClass
    include Supplejack::Request
  end
end

module Supplejack
  describe Request do
    let(:subject) { Supplejack::TestClass.new }

    before do
      Supplejack.stub(:api_key) { '123' }
      Supplejack.stub(:api_url) { 'http://api.org' }
      Supplejack.stub(:timeout) { 20 }
    end

    describe '#get' do
      before { RestClient::Request.stub(:execute).and_return(%( {"search": {}} )) }

      it 'serializes the parameters in the url' do
        RestClient::Request.should_receive(:execute)
                           .with(url: "http://api.org/records.json?#{{ and: { name: 'John' } }.to_query}",
                                 method: :get,
                                 read_timeout: 20,
                                 headers: { 'Authentication-Token': '123' })

        subject.get('/records', and: { name: 'John' })
      end

      it 'parses the JSON returned' do
        RestClient::Request.stub(:execute).and_return(%( {"search": {}} ))

        subject.get('/records').should eq('search' => {})
      end

      it 'logs a error correctly when the response from the API failed' do
        RestClient::Request.stub(:execute).and_return(nil)
        @subscriber = Supplejack::LogSubscriber.new
        Supplejack::LogSubscriber.stub(:new) { @subscriber }
        @subscriber.should_receive(:log_request)

        subject.get('/records')
      end

      context 'request format' do
        it 'executes a request in a json format' do
          RestClient::Request.should_receive(:execute).with(hash_including(url: 'http://api.org/records.json', headers: { 'Authentication-Token': '123' }))

          subject.get('/records')
        end

        it 'overrides the response format with xml' do
          RestClient::Request.should_receive(:execute).with(hash_including(url: 'http://api.org/records.xml', headers: { 'Authentication-Token': '123' }))

          subject.get('/records', {}, format: :xml)
        end
      end

      context 'api key' do
        it 'overrides the api key' do
          RestClient::Request.should_receive(:execute).with(hash_including(url: 'http://api.org/records.json', headers: { 'Authentication-Token': '456' }))

          subject.get('/records', api_key: '456')
        end
      end

      context 'timeout' do
        it 'calculates the timeout' do
          subject.should_receive(:timeout).with(hash_including(timeout: 60))

          subject.get('/', {}, timeout: 60)
        end
      end

      context 'restlclient unavailable' do
        it 'retries request 5 times' do
          RestClient::Request.stub(:execute).and_raise(RestClient::ServiceUnavailable)
          RestClient::Request.should_receive(:execute).exactly(5).times

          expect do
            subject.get('/records')
          end.to raise_error(RestClient::ServiceUnavailable)
        end
      end
    end

    describe '#post' do
      before { RestClient::Request.stub(:execute) }

      it 'executes a post request' do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :post))

        subject.post('/records/1/ucm', {})
      end

      it 'passes the payload along' do
        payload = { 'ucm_record' => { name: 'geocords', value: '1234' } }
        RestClient::Request.should_receive(:execute).with(hash_including(payload: payload.to_json))

        subject.post('/records/1/ucm', {}, payload)
      end

      it 'adds the extra parameters to the post request' do
        subject.should_receive(:full_url).with('/records/1/ucm', nil, {})

        subject.post('/records/1/ucm', { api_key: '12344' }, {})
      end

      it 'adds json headers and converts the payload into json' do
        RestClient::Request.should_receive(:execute).with(
          hash_including(
            headers: { 'Authentication-Token': '123', content_type: :json, accept: :json },
            payload: { records: [{ record_id: 1, position: 1 }, { record_id: 2, position: 2 }] }.to_json
          )
        )

        subject.post('/records/1/ucm', {}, records: [{ record_id: 1, position: 1 }, { record_id: 2, position: 2 }])
      end

      it 'parses the JSON response' do
        RestClient::Request.stub(:execute) { { user: { name: 'John' } }.to_json }

        subject.post('/users', {}, {}).should eq('user' => { 'name' => 'John' })
      end
    end

    describe '#delete' do
      before { RestClient::Request.stub(:execute) }

      it 'executes a delete request' do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :delete))

        subject.delete('/records/1/ucm/1')
      end

      it 'adds the extra parameters to the delete request' do
        subject.should_receive(:full_url).with('/records/1/ucm/1', nil, {})

        subject.delete('/records/1/ucm/1', api_key: '12344')
      end
    end

    describe '#put' do
      before { RestClient::Request.stub(:execute) }

      it 'executes a put request' do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :put))

        subject.put('/records/1/ucm/1')
      end

      it 'passes the payload along' do
        RestClient::Request.should_receive(:execute).with(hash_including(payload: { name: 1 }.to_json))

        subject.put('/records/1/ucm/1', {}, name: 1)
      end

      it 'adds the extra parameters to the put request' do
        subject.should_receive(:full_url).with('/records/1/ucm/1', nil, {})

        subject.put('/records/1/ucm/1', { api_key: '12344' }, {})
      end

      it 'adds json headers and converts the payload into json' do
        RestClient::Request.should_receive(:execute).with(hash_including(headers: { 'Authentication-Token': '123', content_type: :json, accept: :json }, payload: { records: [1, 2, 3] }.to_json))

        subject.put('/records/1/ucm/1', {}, records: [1, 2, 3])
      end

      it 'parses the JSON response' do
        RestClient::Request.stub(:execute) { { user: { name: 'John' } }.to_json }

        subject.put('/users/1', {}, {}).should eq('user' => { 'name' => 'John' })
      end
    end

    describe '#patch' do
      before { RestClient::Request.stub(:execute) }

      it 'executes a patch request' do
        RestClient::Request.should_receive(:execute).with(hash_including(method: :patch))

        subject.patch('/records/1/ucm/1')
      end

      it 'passes the payload along' do
        RestClient::Request.should_receive(:execute).with(hash_including(payload: { name: 1 }.to_json))

        subject.put('/records/1/ucm/1', {}, name: 1)
      end

      it 'adds the extra parameters to the patch request' do
        subject.should_receive(:full_url).with('/records/1/ucm/1', nil, {})

        subject.patch('/records/1/ucm/1', { api_key: '12344' }, {})
      end

      it 'adds json headers and converts the payload into json' do
        RestClient::Request.should_receive(:execute).with(hash_including(headers: { 'Authentication-Token': '123', content_type: :json, accept: :json }, payload: { records: [1, 2, 3] }.to_json))

        subject.patch('/records/1/ucm/1', {}, records: [1, 2, 3])
      end

      it 'parses the JSON response' do
        RestClient::Request.stub(:execute) { { user: { name: 'John' } }.to_json }

        subject.patch('/users/1', {}, {}).should eq('user' => { 'name' => 'John' })
      end
    end

    describe '#timeout' do
      it 'defaults to the timeout in the configuration' do
        expect(subject.send(:timeout)).to eq 20
      end

      it 'defaults to 30 when not set in the configuration' do
        Supplejack.stub(:timeout) { nil }

        expect(subject.send(:timeout)).to eq 15
      end

      it 'overrides the timeout' do
        expect(subject.send(:timeout, timeout: 60)).to eq 60
      end
    end

    describe '#full_url' do
      it 'returns the full url with default api_url, format and api_key' do
        subject.send(:full_url, '/records').should eq('http://api.org/records.json')
      end

      it 'overrides the format' do
        subject.send(:full_url, '/records', 'xml').should eq('http://api.org/records.xml')
      end

      it 'url encodes the parameters' do
        subject.send(:full_url, '/records', nil, api_key: '456', i: { category: 'Images' }).should eq('http://api.org/records.json?api_key=456&i%5Bcategory%5D=Images')
      end

      it 'adds debug=true when enable_debugging is set to true' do
        Supplejack.stub(:enable_debugging) { true }
        subject.send(:full_url, '/records', nil, {}).should eq 'http://api.org/records.json?debug=true'
      end

      it 'handles nil params' do
        subject.send(:full_url, '/records', nil, nil).should eq 'http://api.org/records.json'
      end
    end
  end
end
