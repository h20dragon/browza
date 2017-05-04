require 'spec_helper'

require_relative '../lib/browza'


describe Browza do

  describe 'Create Browser' do

    it 'should create firefox browser wrt SELENIUM_BROWSER' do
      ENV['SELENIUM_BROWSER']='firefox'
      ENV['SELENIUM_PLATFORM']='local'
      Browza::Manager.instance.start()
      expect(Browza::Manager.instance.count).to eql(1)
      expect(Browza::Manager.instance.isFirefox?).to be(true)
      Browza::Manager.instance.quit
      expect(Browza::Manager.instance.count).to eql(0)
    end



  end





end