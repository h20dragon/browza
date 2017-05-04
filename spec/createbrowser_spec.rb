require 'spec_helper'

require_relative '../lib/browza'


describe Browza do

  describe 'Create Browser' do

    it 'should create firefox browser wrt SELENIUM_BROWSER' do
      ENV['SELENIUM_BROWSER']='firefox'
      Browza::Manager.instance.createBrowser()
      expect(Browza::Manager.instance.count).to eql(1)
      expect(Browza::Manager.instance.isFirefox?).to be(true)
      Browza::Manager.instance.quit
      expect(Browza::Manager.instance.count).to eql(0)
    end

    it 'should create chrome browser wrt SELENIUM_BROWSER' do
      ENV['SELENIUM_BROWSER']='chrome'
      Browza::Manager.instance.createBrowser()
      expect(Browza::Manager.instance.count).to eql(1)
      expect(Browza::Manager.instance.browserName).to eql('chrome')
      Browza::Manager.instance.quit
      expect(Browza::Manager.instance.count).to eql(0)
    end


    it 'should create Chrome browser with single parm' do
      Browza::Manager.instance.createBrowser(:chrome)
      expect(Browza::Manager.instance.isChrome?).to be(true)
      Browza::Manager.instance.quit()
      expect(Browza::Manager.instance.count).to eql(0)
    end

    it 'should create Chrome browser with Hash parm' do
      Browza::Manager.instance.createBrowser( { :browserType => :chrome })
      expect(Browza::Manager.instance.isChrome?).to be(true)
      Browza::Manager.instance.quit()
      expect(Browza::Manager.instance.count).to eql(0)
    end

    it 'should create Chrome browser with Hash parm with dimension' do
      Browza::Manager.instance.createBrowser( { :browserType => :chrome, :width => 800, :height => 400 })
      expect(Browza::Manager.instance.isChrome?).to be(true)
      Browza::Manager.instance.quit()
      expect(Browza::Manager.instance.count).to eql(0)
    end

  end


  describe 'Create browser with specified ID' do

    it 'should create Chrome browser with Hash parm with dimension' do
      Browza::Manager.instance.createBrowser( { :id => 'QA000', :browserType => :chrome, :width => 800, :height => 400 })
      Browza::Manager.instance.createBrowser( { :id => 'QA001', :browserType => :chrome, :width => 1024, :height => 800 })

      expect(Browza::Manager.instance.isChrome?).to be(true)
      Browza::Manager.instance.navigate('http://peter.net', 'QA000')

      Browza::Manager.instance.quit('QA001')
      Browza::Manager.instance.quit('QA000')
      expect(Browza::Manager.instance.count).to eql(0)
    end

  end


end