//
//  MaxNativeAdView.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit
import AppLovinSDK

open class MaxNativeAdView: UIView, AdViewProtocol {
  private var nativeAdView: MANativeAdView?
  private var nativeAd: MaxNativeAd?
  private var didReceive: Handler?
  private var didError: Handler?
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    addComponents()
    setConstraints()
    setProperties()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    addComponents()
    setConstraints()
    setProperties()
  }

  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public override func removeFromSuperview() {
    self.nativeAd = nil
    super.removeFromSuperview()
  }
  
  open override func draw(_ rect: CGRect) {
    super.draw(rect)
    setColor()
  }
  
  open func addComponents() {}
  
  open func setConstraints() {}
  
  open func setProperties() {}
  
  open func setColor() {}
  
  public func load(name: String,
                   nativeAdView: MANativeAdView,
                   rootViewController: UIViewController,
                   didReceive: Handler?,
                   didError: Handler?
  ) {
    self.nativeAdView = nativeAdView
    self.didReceive = didReceive
    self.didError = didError
    
    switch AdManager.shared.status(type: .onceUsed(.native), name: name) {
    case false:
      print("[MediationAd] [AdManager] [AdMob] [NativeAd] Ads are not allowed to show! (\(name))")
      errored()
      return
    case true:
      break
    default:
      errored()
      return
    }
    
    if nativeAd == nil {
      guard let native = AdManager.shared.getAd(type: .onceUsed(.native), name: name) as? Native else {
        return
      }
      guard native.status else {
        return
      }
      
      if let nativeAd = AdManager.shared.getNativePreload(name: name) {
        self.nativeAd = nativeAd as? MaxNativeAd
      } else {
        self.nativeAd = MaxNativeAd()
        nativeAd?.config(ad: native, rootViewController: rootViewController)
      }
    }
    
    guard let nativeAd else {
      return
    }
    switch nativeAd.getState() {
    case .receive:
      config(ad: nativeAd.getAd())
    case .error:
      errored()
    case .loading:
      nativeAd.bind { [weak self] in
         guard let self else {
           return
         }
         self.config(ad: nativeAd.getAd())
      } didError: { [weak self] in
        guard let self else {
          return
        }
        self.errored()
      }
    default:
      return
    }
  }
  
  public func destroyAd() -> Bool {
    let state = nativeAd?.getState()
    guard state == .receive || state == .error else {
      return false
    }
    self.nativeAd = nil
    return true
  }
}

extension MaxNativeAdView {
  private func errored() {
    didError?()
  }
  
  private func config(ad: MANativeAd?) {
    guard
      let nativeAd = ad,
      let nativeAdView = nativeAdView
    else {
      return
    }
    
    let adViewBinder = MANativeAdViewBinder(builderBlock: { builder in
      builder.titleLabelTag = 100
      builder.bodyLabelTag = 101
      builder.callToActionButtonTag = 102
      builder.iconImageViewTag = 103
      builder.mediaContentViewTag = 104
      builder.advertiserLabelTag = 105
    })
    nativeAdView.bindViews(with: adViewBinder)

    nativeAdView.titleLabel?.text = nativeAd.title
    
    nativeAdView.mediaContentView = nativeAd.mediaView
    
    if let mediaContentView = nativeAdView.mediaContentView, nativeAd.mediaContentAspectRatio > 0 {
      let heightConstraint = NSLayoutConstraint(
        item: mediaContentView,
        attribute: .height,
        relatedBy: .equal,
        toItem: mediaContentView,
        attribute: .width,
        multiplier: CGFloat(1 / nativeAd.mediaContentAspectRatio),
        constant: 0)
      heightConstraint.isActive = true
    }
    
    nativeAdView.bodyLabel?.text = nativeAd.body
    nativeAdView.bodyLabel?.isHidden = nativeAd.body == nil
    
    nativeAdView.callToActionButton?.setTitle(nativeAd.callToAction, for: .normal)
    nativeAdView.callToActionButton?.isHidden = nativeAd.callToAction == nil
    nativeAdView.callToActionButton?.isUserInteractionEnabled = false
    
    nativeAdView.iconImageView?.image = nativeAd.icon?.image
    nativeAdView.iconImageView?.isHidden = nativeAd.icon == nil
    
    nativeAdView.advertiserLabel?.text = nativeAd.advertiser
    nativeAdView.advertiserLabel?.isHidden = nativeAd.advertiser == nil
    
    didReceive?()
  }
}
