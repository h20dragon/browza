


require_relative '../lib/browza'


puts "Creating Chrome Browser!"


Browza::Manager.instance.createBrowser(:chrome)
Browza::Manager.instance.createBrowser(:chrome)


puts "Navigate to playground"
Browza::Manager.instance.navigate('https://stark-bastion-95510.herokuapp.com/playground')

Browza::Manager.instance.click("//button[text()='Van Halen']")

Browza::Manager.instance.highlight("//button[text()='Van Halen']", 'red')


puts "PRESS ENTER to Continue .."
STDIN.gets
