platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod 'HNScraper'
  pod 'libHN', :git => 'https://github.com/weiran/libHN', :commit => '6759f4ac591f5f36b01158260627ba0bf36eddc1'
	pod 'DZNEmptyDataSet'
  pod 'PromiseKit', '~> 4.x'
  pod 'SkeletonView'
  pod 'Kingfisher'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    if ['PromiseKit'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
      end
    end
  end
end
