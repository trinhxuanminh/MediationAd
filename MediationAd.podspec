Pod::Spec.new do |spec|

  spec.name         = "MediationAd"
  spec.version      = "0.0.4"
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
  
  spec.dependency 'Google-Mobile-Ads-SDK', '11.4.0'
  spec.dependency 'Firebase', '10.25.0'
  spec.dependency 'FirebaseRemoteConfig', '10.25.0'
  spec.dependency 'AppsFlyerFramework', '6.14.3'
  spec.dependency 'AppsFlyer-AdRevenue', '6.14.3'
  spec.dependency 'PurchaseConnector', '6.14.3'
  spec.dependency 'SwiftJWT', '3.6.200'
end
