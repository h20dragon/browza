require 'spec_helper'

require_relative '../lib/browza'


describe "createBrowser()" do

  describe 'ENV SELENIUM_BROWSER=chrome' do

    after(:all) do
      Browza::Manager.instance.quit
    end


    it 'should create firefox browser wrt SELENIUM_BROWSER' do
      ENV['SELENIUM_BROWSER']='chrome'
      Browza::Manager.instance.createBrowser()
      expect(Browza::Manager.instance.count).to eql(1)
    end

    it 'should be firefox' do
      expect(Browza::Manager.instance.isChrome?).to be(true)
    end

  end

  describe 'ENV SELENIUM_BROWSER=firefox' do

    after(:all) do
      Browza::Manager.instance.quit
    end


    it 'should create firefox browser wrt SELENIUM_BROWSER' do
      ENV['SELENIUM_BROWSER']='firefox'
      Browza::Manager.instance.createBrowser()
      expect(Browza::Manager.instance.count).to eql(1)
    end

    it 'should be firefox' do
      expect(Browza::Manager.instance.isFirefox?).to be(true)
    end

  end

end