//
//  MaxNativeAd.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit
import AppLovinSDK
import AppsFlyerAdRevenue

class MaxNativeAd: NSObject, OnceUsedAdProtocol {
  enum State {
    case wait
    case loading
    case receive
    case error
  }
  
  private var nativeAd: MAAd?
  private var nativeAdView: MANativeAdView?
  private var adLoader: MANativeAdLoader?
  private weak var rootViewController: UIViewController?
  private var adUnitID: String?
  private var adName: String?
  private var timeout: Double?
  private var state: State = .wait
  private var didReceive: Handler?
  private var didError: Handler?
  
  func config(ad: Native, rootViewController: UIViewController?, into nativeAdView: UIView?) {
    self.rootViewController = rootViewController
    guard ad.status else {
      return
    }
    guard adUnitID == nil else {
      return
    }
    self.adUnitID = ad.id
    self.adName = ad.name
    self.timeout = ad.timeout
    
    self.nativeAdView = nativeAdView as? MANativeAdView
    let adViewBinder = MANativeAdViewBinder(builderBlock: { builder in
      builder.titleLabelTag = 100
      builder.bodyLabelTag = 101
      builder.callToActionButtonTag = 102
      builder.iconImageViewTag = 103
      builder.mediaContentViewTag = 104
      builder.advertiserLabelTag = 105
    })
    self.nativeAdView?.bindViews(with: adViewBinder)
    self.load()
  }
  
  func getState() -> State {
    return state
  }
  
  func getAd() -> MANativeAd? {
    return nativeAd?.nativeAd
  }
  
  func getAdView() -> MANativeAdView? {
    return nativeAdView
  }
  
  func bind(didReceive: Handler?, didError: Handler?) {
    self.didReceive = didReceive
    self.didError = didError
  }
}

extension MaxNativeAd: MANativeAdDelegate, MAAdRevenueDelegate {
  func didLoadNativeAd(_ nativeAdView: MANativeAdView?, for ad: MAAd) {
    guard state == .loading else {
      return
    }
    print("[MediationAd] [AdManager] [Max] [NativeAd] Did load! (\(String(describing: adUnitID)))")
    let time = TimeManager.shared.end(event: .adLoad(.max, .onceUsed(.native), adUnitID, adName))
    LogEventManager.shared.log(event: .adLoadSuccess(.max, .onceUsed(.native), adUnitID, time))
    self.state = .receive
    
    if let currentNativeAd = nativeAd {
      adLoader?.destroy(currentNativeAd)
    }
    self.nativeAd = ad
    
    if let currentNativeAdView = nativeAdView {
      currentNativeAdView.removeFromSuperview()
    }
    self.nativeAdView = nativeAdView
    
    didReceive?()
    
    
    let network = ad.networkName
    print("[MediationAd] [AdManager] [Max] [NativeAd] Adapter(\(String(describing: network)))!")
  }
  
  func didFailToLoadNativeAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    guard state == .loading else {
      return
    }
    print("[MediationAd] [AdManager] [Max] [NativeAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    LogEventManager.shared.log(event: .adLoadFail(.max, .onceUsed(.native), adUnitID))
    self.state = .error
    didError?()
  }
  
  func didClickNativeAd(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [NativeAd] Did click! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adClick(.max, .onceUsed(.native), adUnitID))
  }
  
  func didPayRevenue(for ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [NativeAd] Did pay revenue(\(ad.revenue))!")
    LogEventManager.shared.log(event: .adPayRevenue(.max, .onceUsed(.native), adUnitID))
    if ad.revenue != 0 {
      LogEventManager.shared.log(event: .adHadRevenue(.max, .onceUsed(.native), adUnitID))
    }
    let adRevenueParams: [AnyHashable: Any] = [
      kAppsFlyerAdRevenueCountry: "US",
      kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
      kAppsFlyerAdRevenueAdType: "Max_Native"
    ]
    
    AppsFlyerAdRevenue.shared().logAdRevenue(
      monetizationNetwork: "applovinmax",
      mediationNetwork: MediationNetworkType.applovinMax,
      eventRevenue: ad.revenue as NSNumber,
      revenueCurrency: "USD",
      additionalParameters: adRevenueParams)
  }
}

extension MaxNativeAd {
  private func load() {
    guard state == .wait else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [Max] [NativeAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    print("[MediationAd] [AdManager] [Max] [NativeAd] Start load! (\(String(describing: adUnitID)))")
    self.state = .loading
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      LogEventManager.shared.log(event: .adLoadRequest(.max, .onceUsed(.native), adUnitID))
      TimeManager.shared.start(event: .adLoad(.max, .onceUsed(.native), adUnitID, adName))
      self.adLoader = MANativeAdLoader(adUnitIdentifier: adUnitID)
      adLoader?.setLocalExtraParameterForKey("google_native_ad_view_tag", value: 99)
      adLoader?.nativeAdDelegate = self
      adLoader?.revenueDelegate = self
      adLoader?.loadAd(into: nativeAdView)
    }
    
    if let timeout {
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
        guard let self else {
          return
        }
        guard state == .loading else {
          return
        }
        print("[MediationAd] [AdManager] [Max] [NativeAd] Load fail (\(String(describing: adUnitID))) - time out!")
        LogEventManager.shared.log(event: .adLoadTimeout(.max, .onceUsed(.native), adUnitID))
        self.state = .error
        didError?()
      }
    }
  }
}
