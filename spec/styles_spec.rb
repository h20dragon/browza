require 'spec_helper'

require_relative '../lib/browza'


describe Browza do



  describe 'Create Browser' do


    it 'should create Chrome browser' do
      Browza::Manager.instance.createBrowser(:chrome)
      expect(Browza::Manager.instance.isChrome?).to be(true)
    end

  end


  describe 'navigate' do

    it 'should navigate to target URL' do
      url = 'file:///Users/pkim/working/hig/_site/pages/desktop/components/autocompletefilter.html'
      Browza::Manager.instance.navigate(url)
      expect(Browza::Manager.instance.isTitle?('HIG: AutoComplete Filter')).to be(true)
    end

    it 'should return empty-string for non-existing style' do
      rc = Browza::Manager.instance.hasStyle?('//a[text()="Button"]', 'foo')
      expect(rc).to eql("")
    end

    it 'should return value of existing style' do
      rc = Browza::Manager.instance.hasStyle?('//a[text()="Button"]', 'font-size')
      expect(rc).to eql('14px')
    end

    it 'should return true for style with specified value' do
      rc = Browza::Manager.instance.hasStyle?('//a[text()="Button"]', 'font-size', '14px')
      expect(rc).to be(true)
    end

    it 'should return true with Regex match \d+px\s*$ for 14px' do
      rc = Browza::Manager.instance.hasStyle?('//a[text()="Button"]', 'font-size', '\s*\d+px\s*$')
      expect(rc).to be(true)
    end

  end


end