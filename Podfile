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
  
  pod 'Google-Mobile-Ads-SDK', '11.9.0' # AdMob
  pod 'GoogleMobileAdsMediationAppLovin' # AppLovin
  pod 'GoogleMobileAdsMediationMintegral' # Mintegral
  pod 'GoogleMobileAdsMediationPangle' # Pangle
  pod 'GoogleMobileAdsMediationFacebook' # Meta Audience Network
  pod 'GoogleMobileAdsMediationVungle' # Liftoff Monetize
  pod 'GoogleMobileAdsMediationFyber' # DT Exchange
  
  pod 'AppLovinSDK', '12.6.1' # AppLovin
  pod 'AppLovinMediationGoogleAdapter' # Google Bidding and Google AdMob
  pod 'AppLovinMediationUnityAdsAdapter' # Unity Ads
  pod 'AppLovinMediationByteDanceAdapter' # Pangle
  pod 'AppLovinMediationFyberAdapter' # DT Exchange
  pod 'AppLovinMediationInMobiAdapter' # InMobi
  pod 'AppLovinMediationIronSourceAdapter' # ironSource
  pod 'AppLovinMediationVungleAdapter' # Liftoff Monetize
  pod 'AppLovinMediationMintegralAdapter' # Mintegral
  pod 'AppLovinMediationFacebookAdapter' # Meta Audience Network
  pod 'AppLovinMediationYandexAdapter' # Yandex
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
