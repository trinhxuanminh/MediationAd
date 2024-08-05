# Sources
source 'https://cdn.cocoapods.org/'
platform :ios, '13.0'

# Settings
use_frameworks! :linkage => :static

inhibit_all_warnings!

target 'MediationAd' do
  pod 'Google-Mobile-Ads-SDK', '11.4.0'
  pod 'Firebase', '10.25.0'
  pod 'FirebaseRemoteConfig', '10.25.0'
  pod 'AppsFlyerFramework', '6.14.3'
  pod 'AppsFlyer-AdRevenue', '6.14.3'
  pod 'PurchaseConnector', '6.14.3'
  pod 'SwiftJWT', '3.6.200'
end

target 'MediationAdExamples' do
  pod 'SnapKit', '5.6.0'
  pod 'NVActivityIndicatorView', '5.1.1'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      end
    end
  end
end
