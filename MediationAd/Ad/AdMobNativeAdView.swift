//
//  AdMobNativeView.swift
//
//
//  Created by Trịnh Xuân Minh on 11/07/2023.
//

import UIKit
import GoogleMobileAds

open class AdMobNativeAdView: UIView, AdViewProtocol {
  enum State {
    case wait
    case loading
    case receive
    case error
  }
  
  private var nativeAdView: GADNativeAdView?
  private var nativeAd: AdMobNativeAd?
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
                   nativeAdView: GADNativeAdView,
                   rootViewController: UIViewController? = nil,
                   didReceive: Handler?,
                   didError: Handler?
  ) {
    self.nativeAdView = nativeAdView
    self.didReceive = didReceive
    self.didError = didError
    
    switch AdManager.shared.status(type: .onceUsed(.native), name: name) {
    case false:
      print("[MediationAd] [AdManager] [NativeAd] Ads are not allowed to show! (\(name))")
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
        self.nativeAd = nativeAd as? AdMobNativeAd
      } else {
        self.nativeAd = AdMobNativeAd()
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
}

extension AdMobNativeAdView {
  private func errored() {
    didError?()
  }
  
  private func config(ad: GADNativeAd?) {
    guard
      let nativeAd = ad,
      let nativeAdView = nativeAdView
    else {
      return
    }

    (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
    
    nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
    
    if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
      let heightConstraint = NSLayoutConstraint(
        item: mediaView,
        attribute: .height,
        relatedBy: .equal,
        toItem: mediaView,
        attribute: .width,
        multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
        constant: 0)
      heightConstraint.isActive = true
    }
    
    (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
    nativeAdView.bodyView?.isHidden = nativeAd.body == nil
    
    (nativeAdView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
    nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
    nativeAdView.callToActionView?.isUserInteractionEnabled = false
    
    (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
    nativeAdView.iconView?.isHidden = nativeAd.icon == nil
    
    (nativeAdView.starRatingView as? UIImageView)?.image = imageOfStars(from: nativeAd.starRating)
    nativeAdView.starRatingView?.isHidden = nativeAd.starRating == nil
    
    (nativeAdView.storeView as? UILabel)?.text = nativeAd.store
    nativeAdView.storeView?.isHidden = nativeAd.store == nil
    
    (nativeAdView.priceView as? UILabel)?.text = nativeAd.price
    nativeAdView.priceView?.isHidden = nativeAd.price == nil
    
    (nativeAdView.advertiserView as? UILabel)?.text = nativeAd.advertiser
    nativeAdView.advertiserView?.isHidden = nativeAd.advertiser == nil
    
    nativeAdView.nativeAd = nativeAd
    
    didReceive?()
  }
  
  private func imageOfStars(from starRating: NSDecimalNumber?) -> UIImage? {
    guard let rating = starRating?.doubleValue else {
      return nil
    }
    guard let image = UIImage(named: "\(Int(rating))_star", in: Bundle.main, compatibleWith: nil) else {
      return nil
    }
    return image
  }
}
