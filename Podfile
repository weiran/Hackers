platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

target 'Hackers' do
	pod 'libHN', :git => 'https://github.com/weiran/libHN'
	pod 'DZNEmptyDataSet'
    pod 'PromiseKit', '~> 4.x'
    pod 'SkeletonView'
    pod 'Kingfisher'
    pod 'Eureka'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if ['PromiseKit', 'SkeletonView'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end
