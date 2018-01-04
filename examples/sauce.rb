


require_relative '../lib/browza'


puts "Creating Chrome Browser!"

sauceName = Time.now.to_s
id = 'QUnit'
cap = { 'name' => sauceName, 'platform' => 'Windows 10', 'browserType' => 'ie', 'version' => '11.0', 'resolution' => '1024x768', 'tags' => 'QUNIT_00' }


rc = Browza::Manager.instance.connectSauce(id, cap)


Browza::Manager.instance.navigate('https://stark-bastion-95510.herokuapp.com/playground')
Browza::Manager.instance.click('//button[text()="Van Halen"]')

puts "PRESS ENTER to Continue .."
STDIN.gets

Browza::Manager.instance.setSauceStatus(id, true)
Browza::Manager.instance.quit('QUnit')
