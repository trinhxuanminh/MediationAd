//
//  CustomNativeAdView.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 27/03/2022.
//

import MediationAd
import UIKit
import GoogleMobileAds
import SnapKit
import NVActivityIndicatorView

class CustomAdMobNativeAdView: AdMobNativeAdView {
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var nativeAdView: GADNativeAdView!
  private lazy var loadingView: NVActivityIndicatorView = {
    let loadingView = NVActivityIndicatorView(frame: .zero)
    loadingView.type = .ballPulse
    loadingView.padding = 30.0
    return loadingView
  }()
  
  override func addComponents() {
    Bundle.main.loadNibNamed("CustomAdMobNativeAdView", owner: self)
    addSubview(contentView)
    
    addSubview(loadingView)
  }
  
  override func setConstraints() {
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    loadingView.snp.makeConstraints { make in
      make.center.equalToSuperview()
      make.width.height.equalTo(20)
    }
  }
  
  override func setProperties() {
    startAnimation()
    load(name: "Native", nativeAdView: nativeAdView, didReceive: { [weak self] in
      guard let self = self else {
        return
      }
      self.stopAnimation()
    }, didError: {
      print("[MediationAdExamples]", "Error")
    })
  }
  
  override func setColor() {
    changeLoading(color: .white)
  }
}

extension CustomAdMobNativeAdView {
  private func startAnimation() {
    nativeAdView.isHidden = true
    loadingView.startAnimating()
  }
  
  private func stopAnimation() {
    nativeAdView.isHidden = false
    loadingView.stopAnimating()
  }
  
  private func changeLoading(color: UIColor) {
    var isAnimating = false
    if loadingView.isAnimating {
      isAnimating = true
      loadingView.stopAnimating()
    }
    loadingView.color = color
    guard isAnimating else {
      return
    }
    loadingView.startAnimating()
  }
}
