require 'spec_helper'

require_relative '../lib/browza'


describe Browza do



  describe 'Create Browser' do


    it 'should create Chrome browser' do
      Browza::Manager.instance.createBrowser(:chrome)
      expect(Browza::Manager.instance.isChrome?).to be(true)
    end



  end


  describe 'Navigate' do

    it 'should navigate with single String parm as URL' do
      Browza::Manager.instance.createBrowser(:chrome)
      Browza::Manager.instance.navigate('http://stark-bastion-95510.herokuapp.com/playground')
      expect(Browza::Manager.instance.isTitle?('H20Dragon Playground')).to be(true)
    end

    it 'should navigate to Playground' do
      Browza::Manager.instance.createBrowser(:chrome)
      Browza::Manager.instance.navigate('http://stark-bastion-95510.herokuapp.com/playground')
      expect(Browza::Manager.instance.isTitle?('H20Dragon Playground')).to be(true)
    end

  end


end