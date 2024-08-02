Pod::Spec.new do |spec|

  spec.name         = "MediationAd"
  spec.version      = "0.0.1"
  spec.summary      = "MediationAd of ProxGlobal"

  spec.description  = <<-DESC
This CocoaPods library helps you do ad handling.
                   DESC

  spec.homepage     = "https://github.com/trinhxuanminh/MediationAd"
  spec.license      = { :type => "MIT", :file => "LICENSE.md" }
  spec.author       = { "trinhxuanminh" => "trinhxuanminh2000@gmail.com" }

  spec.ios.deployment_target = "13.0"
  spec.swift_version = "5.0"

  spec.source       = { :git => "https://github.com/trinhxuanminh/MediationAd.git", :tag => "#{spec.version}" }
  spec.source_files  = "MediationAd/**/*.{h,m,swift}"
  
  spec.static_framework = true
end
