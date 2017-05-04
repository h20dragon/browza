require 'spec_helper'

require_relative '../lib/browza'


describe 'SauceLabs' do



  describe 'Capabilities' do

    it 'should create IE' do
      cap = { 'platform' => 'Windows 10', 'browserType' => 'ie', 'version' => '11.0', 'resolution' => '1024x768', 'tags' => 'QUNIT_00' }
      rc = Browza::Manager.instance.connectSauce('QUnit', cap)
      expect(rc).to be_a_kind_of(Selenium::WebDriver::Remote::Capabilities)
    end

    it 'should execute APIs on Sauce' do
      Browza::Manager.instance.navigate('http://stark-bastion-95510.herokuapp.com/playground')
      Browza::Manager.instance.click('//button[text()="Van Halen"]')
      Browza::Manager.instance.setSauceStatus('QUnit', false)
      puts __FILE__ + (__LINE__).to_s + "  PAUSE"; STDIN.gets

      Browza::Manager.instance.quit()


    end

  end


end