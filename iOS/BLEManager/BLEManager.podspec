Pod::Spec.new do |s|
  s.name         = 'BLEManager'
  s.version      = '0.1.0'
  s.summary      = 'A local library for getting Wi-Fi SSID and Bluetooth manager.'
  s.description  = 'This local library provides a simple way to get the current connected Wi-Fi SSID. It handles location permissions and accuracy authorization on iOS. It also provides a simple way to manage Bluetooth state.'
  s.homepage     = 'https://your-homepage-url.com'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Your Name' => 'liaochenliang@agora.io' }
  s.source       = { :path => '.' }
  s.ios.deployment_target = '14.0'
  s.source_files = 'Class/*.swift'
  s.frameworks   = 'CoreLocation', 'SystemConfiguration'
end