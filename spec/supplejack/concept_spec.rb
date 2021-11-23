# frozen_string_literal: true

require 'spec_helper'

class SupplejackConcept
  include Supplejack::Concept
end

class Search < Supplejack::Search
  def initialize(params = {})
    super
    self.or = { type: ['Person'] }
  end
end

class SpecialSearch < Supplejack::Search
  def initialize(params = {})
    super(params)
    api_params[:and].delete(:format) if api_params && api_params[:and]
  end
end

module Supplejack
  describe Concept do
    it 'initializes its attributes from a JSON string' do
      concept = SupplejackConcept.new(%({"name": "Name", "prefLabel": "Label"}))

      expect(concept.attributes).to eq(name: 'Name', prefLabel: 'Label')
    end

    it 'handles nil params' do
      concept = SupplejackConcept.new(nil)

      expect(concept.attributes).to eq({})
    end

    it 'handles a string as params' do
      concept = SupplejackConcept.new('')

      expect(concept.attributes).to eq({})
    end

    it 'handles a array as params' do
      concept = SupplejackConcept.new([])

      expect(concept.attributes).to eq({})
    end

    it 'raises a NoMethodError for every method call that doesn\'t have a key in the attributes' do
      concept = SupplejackConcept.new

      expect { concept.something }.to raise_error(NoMethodError)
    end

    it 'returns the value when is present in the attributes' do
      concept = SupplejackConcept.new(weird_method: 'Something')

      expect(concept.weird_method).to eq 'Something'
    end

    describe 'id' do
      it 'returns the concept_id' do
        concept = SupplejackConcept.new('concept_id' => '95')

        expect(concept.id).to eq 95
      end

      it 'returns the id' do
        concept = SupplejackConcept.new('id' => '96')

        expect(concept.id).to eq 96
      end
    end

    describe '#name' do
      it 'returns the title attribute value' do
        expect(SupplejackConcept.new(name: 'Name').name).to eq 'Name'
      end

      it 'returns "Unknown" for concepts without a title' do
        expect(SupplejackConcept.new(name: nil).name).to eq 'Unknown'
      end
    end

    %i[next_concept previous_concept next_page previous_page].each do |attr|
      describe attr.to_s do
        it "returns the #{attr}" do
          concept = SupplejackConcept.new(attr => 1)

          expect(concept.send(attr)).to eq 1
        end

        it 'returns the nil' do
          concept = SupplejackConcept.new({})

          expect(concept.send(attr)).to be_nil
        end
      end
    end

    describe '#find' do
      context 'with single concept' do
        it 'raises a Supplejack::ConceptNotFound' do
          allow(SupplejackConcept).to receive(:get).and_raise(RestClient::ResourceNotFound)

          expect { SupplejackConcept.find(1) }.to raise_error(Supplejack::ConceptNotFound)
        end

        it 'raises a Supplejack::MalformedRequest' do
          expect { SupplejackConcept.find('replace_this') }.to raise_error(Supplejack::MalformedRequest)
        end

        it 'requests the concept from the API' do
          allow(SupplejackConcept).to receive(:get).with('/concepts/1', {}).and_return('concept' => {})

          SupplejackConcept.find(1)
        end

        it 'initializes a new SupplejackConcept object' do
          allow(SupplejackConcept).to receive(:get).and_return('concept_id' => '1', 'name' => 'Wellington')
          concept = SupplejackConcept.find(1)

          expect(concept.class).to eq SupplejackConcept
          expect(concept.name).to eq 'Wellington'
        end

        it 'send the fields defined in the configuration' do
          allow(Supplejack).to receive(:fields).and_return(%i[verbose default])
          allow(SupplejackConcept).to receive(:get).with('/concepts/1', {}).and_return('concept' => {})

          SupplejackConcept.find(1)
        end
      end
    end

    describe '#all' do
      it 'calls the get method' do
        allow(SupplejackConcept).to receive(:get).with('/concepts', {}).and_return({})

        SupplejackConcept.all
      end
    end
  end
end
