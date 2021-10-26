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
      allow(Supplejack).to receive(:api_key).and_return('123')
      allow(Supplejack).to receive(:api_url).and_return('http://api.org')
      allow(Supplejack).to receive(:timeout).and_return(20)
    end

    describe '#get' do
      before { allow(RestClient::Request).to receive(:execute).and_return(%( {"search": {}} )) }

      context 'when authetication_token not passed in options' do
        it 'serializes the parameters in the url' do
          expect(RestClient::Request).to receive(:execute)
            .with(url: "http://api.org/records.json?#{{ and: { name: 'John' } }.to_query}",
                  method: :get, read_timeout: 20,
                  headers: { 'Authentication-Token': '123' })

          subject.get('/records', and: { name: 'John' })
        end

        it 'parses the JSON returned' do
          expect(subject.get('/records')).to eq('search' => {})
        end

        it 'logs a error correctly when the response from the API failed' do
          allow(RestClient::Request).to receive(:execute).and_return(nil)

          expect_any_instance_of(Supplejack::LogSubscriber).to receive(:log_request)

          subject.get('/records')
        end

        context 'request format' do
          it 'executes a request in a json format' do
            expect(RestClient::Request).to receive(:execute).with(hash_including(url: 'http://api.org/records.json', headers: { 'Authentication-Token': '123' }))

            subject.get('/records')
          end

          it 'overrides the response format with xml' do
            expect(RestClient::Request).to receive(:execute).with(hash_including(url: 'http://api.org/records.xml', headers: { 'Authentication-Token': '123' }))

            subject.get('/records', {}, format: :xml)
          end
        end

        context 'timeout' do
          it 'calculates the timeout' do
            expect(subject).to receive(:timeout).with(hash_including(timeout: 60))

            subject.get('/', {}, timeout: 60)
          end
        end

        context 'restlclient unavailable' do
          it 'retries request 5 times' do
            allow(RestClient::Request).to receive(:execute).and_raise(RestClient::ServiceUnavailable)
            expect(RestClient::Request).to receive(:execute).exactly(5).times

            expect do
              subject.get('/records')
            end.to raise_error(RestClient::ServiceUnavailable)
          end
        end
      end

      context 'when authetication_token is passed in options' do
        it 'overrides the Supplejack.api_key' do
          expect(RestClient::Request).to receive(:execute).with(hash_including(url: 'http://api.org/records.json', headers: { 'Authentication-Token': '456' }))

          subject.get('/records', {}, { authetication_token: '456' })
        end
      end
    end

    describe '#post' do
      before { allow(RestClient::Request).to receive(:execute).and_return(true) }

      context 'when authetication_token not passed in options' do
        it 'executes a post request' do
          expect(RestClient::Request).to receive(:execute).with(hash_including(method: :post))

          subject.post('/records/1/ucm', {})
        end

        it 'passes the payload along' do
          payload = { 'ucm_record' => { name: 'geocords', value: '1234' } }

          expect(RestClient::Request).to receive(:execute).with(hash_including(payload: payload.to_json))

          subject.post('/records/1/ucm', {}, payload)
        end

        it 'adds the extra parameters to the post request' do
          expect(subject).to receive(:full_url).with('/records/1/ucm', nil, {})

          subject.post('/records/1/ucm', {}, {})
        end

        it 'adds json headers and converts the payload into json' do
          expect(RestClient::Request).to receive(:execute).with(
            hash_including(
              headers: { 'Authentication-Token': '123', content_type: :json, accept: :json },
              payload: { records: [{ record_id: 1, position: 1 }, { record_id: 2, position: 2 }] }.to_json
            )
          )

          subject.post('/records/1/ucm', {}, records: [{ record_id: 1, position: 1 }, { record_id: 2, position: 2 }])
        end

        it 'parses the JSON response' do
          allow(RestClient::Request).to receive(:execute).and_return({ user: { name: 'John' } }.to_json)

          expect(subject.post('/users', {}, {})).to eq('user' => { 'name' => 'John' })
        end
      end

      context 'when authetication_token is passed in options' do
        it 'overrides the Supplejack.api_key' do
          expect(RestClient::Request).to receive(:execute).with(
            hash_including(
              headers: { 'Authentication-Token': '456', content_type: :json, accept: :json },
              payload: { records: [{ record_id: 1 }] }.to_json
            )
          )

          subject.post('/records/1/ucm', {}, { records: [{ record_id: 1 }] }, { authetication_token: '456' })
        end
      end
    end

    describe '#delete' do
      before { allow(RestClient::Request).to receive(:execute).and_return(true) }

      it 'executes a delete request' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(method: :delete))

        subject.delete('/records/1/ucm/1')
      end

      it 'adds the extra parameters to the delete request' do
        expect(subject).to receive(:full_url).with('/records/1/ucm/1', nil, {})

        subject.delete('/records/1/ucm/1', {}, {})
      end
    end

    describe '#put' do
      before { allow(RestClient::Request).to receive(:execute).and_return(true) }

      it 'executes a put request' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(method: :put))

        subject.put('/records/1/ucm/1')
      end

      it 'passes the payload along' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(payload: { name: 1 }.to_json))

        subject.put('/records/1/ucm/1', {}, name: 1)
      end

      it 'adds the extra parameters to the put request' do
        expect(subject).to receive(:full_url).with('/records/1/ucm/1', nil, {})

        subject.put('/records/1/ucm/1', {}, {})
      end

      it 'adds json headers and converts the payload into json' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(headers: { 'Authentication-Token': '123', content_type: :json, accept: :json }, payload: { records: [1, 2, 3] }.to_json))

        subject.put('/records/1/ucm/1', {}, records: [1, 2, 3])
      end

      it 'parses the JSON response' do
        allow(RestClient::Request).to receive(:execute).and_return({ user: { name: 'John' } }.to_json)

        expect(subject.put('/users/1', {}, {})).to eq('user' => { 'name' => 'John' })
      end
    end

    describe '#patch' do
      before { allow(RestClient::Request).to receive(:execute).and_return(true) }

      it 'executes a patch request' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(method: :patch))

        subject.patch('/records/1/ucm/1')
      end

      it 'passes the payload along' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(payload: { name: 1 }.to_json))

        subject.put('/records/1/ucm/1', {}, name: 1)
      end

      it 'adds the extra parameters to the patch request' do
        expect(subject).to receive(:full_url).with('/records/1/ucm/1', nil, {})

        subject.patch('/records/1/ucm/1', {}, {})
      end

      it 'adds json headers and converts the payload into json' do
        expect(RestClient::Request).to receive(:execute).with(hash_including(headers: { 'Authentication-Token': '123', content_type: :json, accept: :json }, payload: { records: [1, 2, 3] }.to_json))

        subject.patch('/records/1/ucm/1', {}, records: [1, 2, 3])
      end

      it 'parses the JSON response' do
        allow(RestClient::Request).to receive(:execute).and_return({ user: { name: 'John' } }.to_json)

        expect(subject.patch('/users/1', {}, {})).to eq('user' => { 'name' => 'John' })
      end
    end

    describe '#timeout' do
      it 'defaults to the timeout in the configuration' do
        expect(subject.send(:timeout)).to eq 20
      end

      it 'defaults to 30 when not set in the configuration' do
        allow(Supplejack).to receive(:timeout).and_return(nil)

        expect(subject.send(:timeout)).to eq 15
      end

      it 'overrides the timeout' do
        expect(subject.send(:timeout, timeout: 60)).to eq 60
      end
    end

    describe '#full_url' do
      it 'returns the full url with default api_url, format and api_key' do
        expect(subject.send(:full_url, '/records')).to eq('http://api.org/records.json')
      end

      it 'overrides the format' do
        expect(subject.send(:full_url, '/records', 'xml')).to eq('http://api.org/records.xml')
      end

      it 'url encodes the parameters' do
        expect(subject.send(:full_url, '/records', nil, api_key: '456', i: { category: 'Images' })).to eq('http://api.org/records.json?api_key=456&i%5Bcategory%5D=Images')
      end

      it 'adds debug=true when enable_debugging is set to true' do
        allow(Supplejack).to receive(:enable_debugging).and_return(true)

        expect(subject.send(:full_url, '/records', nil, {})).to eq 'http://api.org/records.json?debug=true'
      end

      it 'handles nil params' do
        expect(subject.send(:full_url, '/records', nil, nil)).to eq 'http://api.org/records.json'
      end
    end
  end
end
