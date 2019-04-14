platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
  pod 'HNScraper', :git => 'https://github.com/weiran/HNScraper.git'
  pod 'DZNEmptyDataSet'
  pod 'PromiseKit/CorePromise'
  pod 'SkeletonView'
  pod 'Kingfisher'
  pod 'Loaf'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      if target.name == "HNScraper"
        config.build_settings['SWIFT_VERSION'] = '4.2'
      end
    end
  end
end
