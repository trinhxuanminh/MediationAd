//
//  MaxNativeAdView.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit
import SnapKit
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
        nativeAd?.config(ad: native, rootViewController: rootViewController, into: nativeAdView)
      }
    }
    
    guard let nativeAd else {
      return
    }
    switch nativeAd.getState() {
    case .receive:
      config(ad: nativeAd.getAdView())
    case .error:
      errored()
    case .loading:
      nativeAd.bind { [weak self] in
         guard let self else {
           return
         }
         self.config(ad: nativeAd.getAdView())
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
  
  @MainActor
  private func config(ad: MANativeAdView?) {
    guard let nativeAdView = ad else {
      return
    }
    self.nativeAdView?.removeFromSuperview()
    self.addSubview(nativeAdView)
    nativeAdView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
    self.nativeAdView = nativeAdView
    didReceive?()
  }
}
