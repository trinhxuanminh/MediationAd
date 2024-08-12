Pod::Spec.new do |spec|

  spec.name         = "MediationAd"
  spec.version      = "0.0.9"
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
  
  spec.dependency 'Google-Mobile-Ads-SDK', '11.5.0'
  spec.dependency 'Firebase', '10.25.0'
  spec.dependency 'FirebaseRemoteConfig', '10.25.0'
  spec.dependency 'AppsFlyerFramework', '6.14.3'
  spec.dependency 'AppsFlyer-AdRevenue', '6.14.3'
  spec.dependency 'PurchaseConnector', '6.14.3'
  spec.dependency 'SwiftJWT', '3.6.200'
  spec.dependency 'SnapKit', '5.6.0'
  spec.dependency 'NVActivityIndicatorView', '5.1.1'
  
  spec.dependency 'AppLovinSDK', '12.6.0' # AppLovin
  spec.dependency 'AppLovinMediationGoogleAdManagerAdapter', '11.5.0.0' # Google Ad Manager
  spec.dependency 'AppLovinMediationGoogleAdapter', '11.5.0.0' # Google Bidding and Google AdMob
  spec.dependency 'AppLovinMediationUnityAdsAdapter', '4.12.1.0' # Unity Ads
  spec.dependency 'AppLovinMediationByteDanceAdapter', '6.1.0.6.0' # Pangle
  spec.dependency 'AppLovinMediationFyberAdapter', '8.3.1.0' # DT Exchange
  spec.dependency 'AppLovinMediationInMobiAdapter', '10.7.5.0' # InMobi
  spec.dependency 'AppLovinMediationIronSourceAdapter', '8.1.0.0.1' # ironSource
  spec.dependency 'AppLovinMediationVungleAdapter', '7.4.0.0' # Liftoff Monetize
  spec.dependency 'AppLovinMediationMintegralAdapter', '7.6.9.0.0' # Mintegral
  spec.dependency 'AppLovinMediationFacebookAdapter', '6.15.0.0' # Meta Audience Network
  spec.dependency 'AppLovinMediationYandexAdapter', '7.0.1.0' # Yandex
end
