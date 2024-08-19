# Sources
source 'https://cdn.cocoapods.org/'
platform :ios, '14.0'

# Settings
use_frameworks! :linkage => :static

inhibit_all_warnings!

target 'MediationAd' do
  pod 'SnapKit', '5.6.0'
  pod 'Firebase', '10.25.0'
  pod 'FirebaseRemoteConfig', '10.25.0'
  pod 'AppsFlyerFramework', '6.14.3'
  pod 'AppsFlyer-AdRevenue', '6.14.3'
  pod 'PurchaseConnector', '6.14.3'
  pod 'SwiftJWT', '3.6.200'
  pod 'Google-Mobile-Ads-SDK', '11.5.0' # AdMob
  
  pod 'AppLovinSDK', '12.6.0' # AppLovin
  pod 'AppLovinMediationGoogleAdManagerAdapter', '11.5.0.0' # Google Ad Manager
  pod 'AppLovinMediationGoogleAdapter', '11.5.0.0' # Google Bidding and Google AdMob
  pod 'AppLovinMediationUnityAdsAdapter', '4.12.1.0' # Unity Ads
  pod 'AppLovinMediationByteDanceAdapter', '6.1.0.6.0' # Pangle
  pod 'AppLovinMediationFyberAdapter', '8.3.1.0' # DT Exchange
  pod 'AppLovinMediationInMobiAdapter', '10.7.5.0' # InMobi
  pod 'AppLovinMediationIronSourceAdapter', '8.1.0.0.1' # ironSource
  pod 'AppLovinMediationVungleAdapter', '7.4.0.0' # Liftoff Monetize
  pod 'AppLovinMediationMintegralAdapter', '7.6.9.0.0' # Mintegral
  pod 'AppLovinMediationFacebookAdapter', '6.15.0.0' # Meta Audience Network
  pod 'AppLovinMediationYandexAdapter', '7.0.1.0' # Yandex
end

target 'MediationAdExamples' do
  pod 'SnapKit', '5.6.0'
  pod 'NVActivityIndicatorView', '5.1.1'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      end
    end
  end
end
