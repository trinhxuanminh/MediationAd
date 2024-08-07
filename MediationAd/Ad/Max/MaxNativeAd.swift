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
  
  private var nativeAd: MANativeAd?
  private var adLoader: MANativeAdLoader?
  private weak var rootViewController: UIViewController?
  private var adUnitID: String?
  private var timeout: Double?
  private var state: State = .wait
  private var didReceive: Handler?
  private var didError: Handler?
  
  func config(ad: Native, rootViewController: UIViewController?) {
    self.rootViewController = rootViewController
    guard ad.status else {
      return
    }
    guard adUnitID == nil else {
      return
    }
    self.adUnitID = ad.id
    self.timeout = ad.timeout
    self.load()
  }
  
  func getState() -> State {
    return state
  }
  
  func getAd() -> MANativeAd? {
    return nativeAd
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
    self.state = .receive
    self.nativeAd = ad.nativeAd
    didReceive?()
  }
  
  func didFailToLoadNativeAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    guard state == .loading else {
      return
    }
    print("[MediationAd] [AdManager] [Max] [NativeAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    self.state = .error
    didError?()
  }
  
  func didClickNativeAd(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [NativeAd] Did click! (\(String(describing: adUnitID)))")
  }
  
  func didPayRevenue(for ad: MAAd) {
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
      self.adLoader = MANativeAdLoader(adUnitIdentifier: adUnitID)
      adLoader?.nativeAdDelegate = self
      adLoader?.revenueDelegate = self
      adLoader?.loadAd()
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
        self.state = .error
        didError?()
      }
    }
  }
}
