Pod::Spec.new do |spec|

  spec.name         = "MediationAd"
  spec.version      = "0.0.22"
  spec.summary      = "MediationAd of ProxGlobal"

  spec.description  = <<-DESC
This CocoaPods library helps you do ad handling.
                   DESC

  spec.homepage     = "https://github.com/trinhxuanminh/MediationAd"
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }
  spec.author       = { "trinhxuanminh" => "trinhxuanminh2000@gmail.com" }

  spec.ios.deployment_target = '13.0'
  spec.swift_version = "5.2"

  spec.source       = { :git => "https://github.com/trinhxuanminh/MediationAd.git", :tag => "#{spec.version}" }
  spec.source_files  = "MediationAd/**/*.{h,m,swift}"
  
  spec.static_framework = true
  
  spec.dependency 'Firebase', '10.25.0'
  spec.dependency 'FirebaseRemoteConfig', '10.25.0'
  spec.dependency 'AppsFlyerFramework', '6.14.3'
  spec.dependency 'AppsFlyer-AdRevenue', '6.14.3'
  spec.dependency 'PurchaseConnector', '6.14.3'
  spec.dependency 'SwiftJWT', '3.6.200'
  spec.dependency 'SnapKit', '5.6.0'
  spec.dependency 'NVActivityIndicatorView', '5.1.1'
    
  spec.dependency 'Google-Mobile-Ads-SDK', '11.9.0' # AdMob
  spec.dependency 'GoogleMobileAdsMediationAppLovin' # AppLovin
  spec.dependency 'GoogleMobileAdsMediationMintegral' # Mintegral
  spec.dependency 'GoogleMobileAdsMediationPangle' # Pangle
  spec.dependency 'GoogleMobileAdsMediationFacebook' # Meta Audience Network
  spec.dependency 'GoogleMobileAdsMediationVungle' # Liftoff Monetize
  spec.dependency 'GoogleMobileAdsMediationFyber' # DT Exchange
  
  spec.dependency 'AppLovinSDK', '12.6.1' # AppLovin
  spec.dependency 'AppLovinMediationGoogleAdapter' # Google Bidding and Google AdMob
  spec.dependency 'AppLovinMediationUnityAdsAdapter' # Unity Ads
  spec.dependency 'AppLovinMediationByteDanceAdapter' # Pangle
  spec.dependency 'AppLovinMediationFyberAdapter' # DT Exchange
  spec.dependency 'AppLovinMediationInMobiAdapter' # InMobi
  spec.dependency 'AppLovinMediationIronSourceAdapter' # ironSource
  spec.dependency 'AppLovinMediationVungleAdapter' # Liftoff Monetize
  spec.dependency 'AppLovinMediationMintegralAdapter' # Mintegral
  spec.dependency 'AppLovinMediationFacebookAdapter' # Meta Audience Network
  spec.dependency 'AppLovinMediationYandexAdapter' # Yandex
end
