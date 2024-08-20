//
//  MaxAppOpenAd.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 06/08/2024.
//

import UIKit
import AppLovinSDK
import AppsFlyerAdRevenue

class MaxAppOpenAd: NSObject, ReuseAdProtocol {
  private var appOpenAd: MAAppOpenAd?
  private var adUnitID: String?
  private var presentState = false
  private var isLoading = false
  private var retryAttempt = 0
  private var didLoadFail: Handler?
  private var didLoadSuccess: Handler?
  private var didShowFail: Handler?
  private var willPresent: Handler?
  private var didEarnReward: Handler?
  private var didHide: Handler?
  
  func config(didFail: Handler?, didSuccess: Handler?) {
    self.didLoadFail = didFail
    self.didLoadSuccess = didSuccess
  }
  
  func config(id: String) {
    self.adUnitID = id
    load()
  }
  
  func isPresent() -> Bool {
    return presentState
  }
  
  func isExist() -> Bool {
    return appOpenAd != nil
  }
  
  func show(rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard isReady() else {
      print("[MediationAd] [AdManager] [Max] [AppOpenAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [Max] [AppOpenAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.max, .reuse(.appOpen), adUnitID))
    appOpenAd?.show()
  }
}

extension MaxAppOpenAd: MAAdDelegate, MAAdRevenueDelegate {
  func didLoad(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Did load! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adLoadSuccess(.max, .reuse(.appOpen), adUnitID))
    self.isLoading = false
    self.retryAttempt = 0
    self.didLoadSuccess?()
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    LogEventManager.shared.log(event: .adLoadFail(.max, .reuse(.appOpen), adUnitID))
    self.isLoading = false
    self.retryAttempt += 1
    self.didLoadFail?()
  }
  
  func didDisplay(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.max, .reuse(.appOpen), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func didClick(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Did click! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adClick(.max, .reuse(.appOpen), adUnitID))
  }
  
  func didFail(toDisplay ad: MAAd, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.max, .reuse(.appOpen), adUnitID))
    didShowFail?()
    self.appOpenAd = nil
    load()
  }
  
  func didHide(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.max, .reuse(.appOpen), adUnitID))
    didHide?()
    self.appOpenAd = nil
    self.presentState = false
    load()
  }
  
  func didPayRevenue(for ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Did pay revenue(\(ad.revenue))!")
    LogEventManager.shared.log(event: .adPayRevenue(.max, .reuse(.appOpen), adUnitID))
    if ad.revenue != 0 {
      LogEventManager.shared.log(event: .adHadRevenue(.max, .reuse(.appOpen), adUnitID))
    }
    let adRevenueParams: [AnyHashable: Any] = [
      kAppsFlyerAdRevenueCountry: "US",
      kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
      kAppsFlyerAdRevenueAdType: "Max_AppOpen"
    ]

    AppsFlyerAdRevenue.shared().logAdRevenue(
      monetizationNetwork: "applovinmax",
      mediationNetwork: MediationNetworkType.applovinMax,
      eventRevenue: ad.revenue as NSNumber,
      revenueCurrency: "USD",
      additionalParameters: adRevenueParams)
  }
}

extension MaxAppOpenAd {
  private func isReady() -> Bool {
    if !isExist(), retryAttempt >= 1 {
      load()
    }
    return isExist()
  }
  
  private func load() {
    guard !isLoading else {
      return
    }
    
    guard !isExist() else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [Max] [AppOpenAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [Max] [AppOpenAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.max, .reuse(.appOpen), adUnitID))
      
      self.appOpenAd = MAAppOpenAd(adUnitIdentifier: adUnitID)
      appOpenAd?.delegate = self
      appOpenAd?.revenueDelegate = self
      appOpenAd?.load()
    }
  }
}
