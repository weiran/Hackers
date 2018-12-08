platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod 'HNScraper', :git => 'https://github.com/weiran/HNScraper.git'
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
