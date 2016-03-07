# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government,
# and is licensed under the GNU General Public License, version 3.
# See https://github.com/DigitalNZ/supplejack_client for details.
#
# Supplejack was created by DigitalNZ at the National Library of NZ
# and the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

class SupplejackConcept
  include Supplejack::Concept
end

class Search < Supplejack::Search
  def initialize(params={})
    super
    self.or = {:type => ['Person']}
  end
end

class SpecialSearch < Supplejack::Search
  def initialize(params={})
    super(params)
    if self.api_params && self.api_params[:and]
      self.api_params[:and].delete(:format)
    end
  end
end

module Supplejack
  describe Concept do
    it 'initializes its attributes from a JSON string' do
      concept = SupplejackConcept.new(%{{"name": "Name", "prefLabel": "Label"}})
      concept.attributes.should eq({name: 'Name', prefLabel: 'Label'})
    end

    it 'handles nil params' do
      concept = SupplejackConcept.new(nil)
      concept.attributes.should eq({})
    end

    it 'handles a string as params' do
      concept = SupplejackConcept.new('')
      concept.attributes.should eq({})
    end

    it 'handles a array as params' do
      concept = SupplejackConcept.new([])
      concept.attributes.should eq({})
    end

    it 'raises a NoMethodError for every method call that doesn\'t have a key in the attributes' do
      concept = SupplejackConcept.new
      expect { concept.something }.to raise_error(NoMethodError)
    end

    it 'should return the value when is present in the attributes' do
      concept = SupplejackConcept.new(:weird_method => 'Something')
      concept.weird_method.should eq 'Something'
    end

    describe 'id' do
      it 'returns the concept_id' do
        concept = SupplejackConcept.new({'concept_id' => '95'})
        concept.id.should eq 95
      end

      it 'returns the id' do
        concept = SupplejackConcept.new({'id' => '96'})
        concept.id.should eq 96
      end
    end

    describe '#name' do
      it 'returns the title attribute value' do
        SupplejackConcept.new(name: 'Name').name.should eq 'Name'
      end

      it 'returns "Unknown" for concepts without a title' do
        SupplejackConcept.new(name: nil).name.should eq 'Unknown'
      end
    end

    [:next_concept, :previous_concept, :next_page, :previous_page].each do |attr|
      describe "#{attr}" do
        it "returns the #{attr}" do
          concept = SupplejackConcept.new({attr => 1})
          concept.send(attr).should eq 1
        end

        it "returns the nil" do
          concept = SupplejackConcept.new({})
          concept.send(attr).should be_nil
        end
      end
    end

    describe '#find' do
      context 'single concept' do
        it 'raises a Supplejack::ConceptNotFound' do
          SupplejackConcept.stub(:get).and_raise(RestClient::ResourceNotFound)
          expect { SupplejackConcept.find(1) }.to raise_error(Supplejack::ConceptNotFound)
        end

        it 'raises a Supplejack::MalformedRequest' do
          expect { SupplejackConcept.find('replace_this') }.to raise_error(Supplejack::MalformedRequest)
        end

        it 'requests the concept from the API' do
          SupplejackConcept.should_receive(:get).with('/concepts/1', {}).and_return({'concept' => {}})
          SupplejackConcept.find(1)
        end

        it 'initializes a new SupplejackConcept object' do
          SupplejackConcept.stub(:get).and_return({'concept_id' => '1', 'name' => 'Wellington'})
          concept = SupplejackConcept.find(1)
          concept.class.should eq SupplejackConcept
          concept.id.should eq 1
          concept.name.should eq 'Wellington'
        end

        it 'send the fields defined in the configuration' do
          Supplejack.stub(:fields) { [:verbose,:default] }
          SupplejackConcept.should_receive(:get).with('/concepts/1', {}).and_return({'concept' => {}})
          SupplejackConcept.find(1)
        end
      end
    end
  end
end
