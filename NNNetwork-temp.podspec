Pod::Spec.new do |s|
  s.name         = 'NNNetwork'
  s.version      = '0.0.3'
  s.summary      = 'Networking categories, OAuth and read later clients.'
  s.homepage     = 'http://github.com/tomazsh/NNNetwork'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Tomaz Nedeljko' => 'tomaz@nedeljko.com' }
  s.source       = { :git => 'https://github.com/weiran/NNNetwork.git' }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.source_files = 'NNNetwork'
  s.resources = 'Resources/*.png'
  s.ios.frameworks = 'Security', 'MobileCoreServices', 'SystemConfiguration', 'UIKit'
  s.osx.frameworks = 'Security', 'CoreServices', 'SystemConfiguration'
  s.requires_arc = true
  s.dependency 'AFNetworking', '~> 1.3.2'
  s.dependency 'SSKeychain', '~> 1.2.0'
end
