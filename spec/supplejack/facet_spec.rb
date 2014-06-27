# The Supplejack Client code is Crown copyright (C) 2014, New Zealand Government, 
# and is licensed under the GNU General Public License, version 3.
# One component is a third party component. See https://github.com/DigitalNZ/supplejack_api for details. 
# 
# Supplejack was created by DigitalNZ at the National Library of NZ and 
# the Department of Internal Affairs. http://digitalnz.org/supplejack

require 'spec_helper'

module Supplejack
  describe Facet do
    
    it 'initializes the facet with a name' do
      facet = Supplejack::Facet.new('description', {})
      facet.name.should eq('description')
    end
    
    it 'initializes the facet with values' do
      facet = Supplejack::Facet.new('location', {'Wellington' => 100, 'Auckland' => 10})
      facet.values.should eq({'Wellington' => 100, 'Auckland' => 10})
    end

    context 'sorting' do
      let(:facet) { Supplejack::Facet.new('location', {'Wellington' => 100, 'Auckland' => 10, 'Dunedin' => 5, 'Queenstown' => 30}) }

      it 'sorts by alphabetical order set in config' do
        Supplejack.stub(:facets_sort) { :index }
        facet.values.keys.should eq ['Auckland', 'Dunedin', 'Queenstown', 'Wellington']
        facet.values.values.should eq [10, 5, 30, 100]
      end

      it 'sorts by count set in the config' do
        Supplejack.stub(:facets_sort) { :count }
        facet.values.keys.should eq ['Wellington', 'Queenstown', 'Auckland', 'Dunedin']
        facet.values.values.should eq [100, 30, 10, 5]
      end

      it 'overrides the global facets sort' do
        Supplejack.stub(:facets_sort) { :count }
        facet.values(:index).keys.should eq ['Auckland', 'Dunedin', 'Queenstown', 'Wellington']
      end
    end
  end
end
