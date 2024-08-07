//
//  CustomAdMobNativeAdView.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 27/03/2022.
//

import UIKit
import MediationAd
import GoogleMobileAds

class CustomAdMobNativeAdView: AdMobNativeAdView {
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var nativeAdView: GADNativeAdView!
  
  override func addComponents() {
    loadNibNamed()
    addSubview(contentView)
  }
  
  override func setConstraints() {
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
  }
}

extension CustomAdMobNativeAdView {
  func load(name: String, didReceive: Handler? = nil, didError: Handler? = nil) {
    guard let topVC = UIApplication.topViewController() else {
      return
    }
    load(name: name,
         nativeAdView: nativeAdView,
         rootViewController: topVC,
         didReceive: didReceive,
         didError: didError)
  }
}
