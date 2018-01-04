


require_relative '../lib/browza'


puts "Creating Chrome Browser!"


ENV['SELENIUM_BROWSER']='firefox'
ENV['SELENIUM_PLATFORM']='local'
Browza::Manager.instance.start

Browza::Manager.instance.addModel('./model.json')

#Browza::Manager.instance.createBrowser()


puts "Navigate to playground"
Browza::Manager.instance.navigate('https://stark-bastion-95510.herokuapp.com/playground')

#Browza::Manager.instance.click("//button[text()='Van Halen']")
Browza::Manager.instance.click("page(exPage).get(vh)")


#Browza::Manager.instance.highlight("//button[text()='Van Halen']", 'red')
Browza::Manager.instance.highlight("page(exPage).get(vh)", 'red')

puts "PRESS ENTER to Continue .."
STDIN.gets

Browza::Manager.instance.quit()
