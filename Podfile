platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!
source 'https://cdn.cocoapods.org/‘ # For Travis

target 'Hackers' do
  pod 'HNScraper', :git => 'https://github.com/weiran/HNScraper.git', :branch => 'master'
  pod 'PromiseKit/CorePromise'
  pod 'Kingfisher'
  pod 'Loaf'
  pod 'SwipeCellKit'
  pod 'Swinject', '~> 2.6.2' # SwinjectStoryboard needs updating
  pod 'SwinjectStoryboard'
  pod 'BulletinBoard'
  pod 'WhatsNewKit'
  
  pod 'SwiftLint'
end

target 'HackersUITests' do
  pod 'DeviceKit'
end
