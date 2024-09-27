//
//  MaxInterstitialAd.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 06/08/2024.
//

import UIKit
import AppLovinSDK
import AppsFlyerAdRevenue

class MaxInterstitialAd: NSObject, ReuseAdProtocol {
  private var interstitialAd: MAInterstitialAd?
  private var adUnitID: String?
  private var placement: String?
  private var name: String?
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
  
  func config(id: String, name: String) {
    self.adUnitID = id
    self.name = name
    load()
  }
  
  func isPresent() -> Bool {
    return presentState
  }
  
  func isExist() -> Bool {
    return interstitialAd != nil
  }
  
  func show(placement: String,
            rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard !presentState else {
      print("[MediationAd] [AdManager] [Max] [InterstitialAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard isReady() else {
      print("[MediationAd] [AdManager] [Max] [InterstitialAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Requested to show! (\(String(describing: adUnitID)))")
    self.placement = placement
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.max, .reuse(.interstitial), adUnitID))
    interstitialAd?.show()
  }
}

extension MaxInterstitialAd: MAAdDelegate, MAAdRevenueDelegate {
  func didLoad(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Did load! (\(String(describing: adUnitID)))")
    if let name {
      let time = TimeManager.shared.end(event: .adLoad(name))
      LogEventManager.shared.log(event: .adLoadSuccess(.max, name, time))
    }
    self.isLoading = false
    self.retryAttempt = 0
    self.didLoadSuccess?()
    
    let network = ad.networkName
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Adapter(\(String(describing: network)))!")
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    self.isLoading = false
    self.retryAttempt += 1
    LogEventManager.shared.log(event: .adLoadRetryFail(.max, .reuse(.interstitial), adUnitID))
    self.didLoadFail?()
  }
  
  func didDisplay(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.max, .reuse(.interstitial), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func didClick(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [AppOpenAd] Did click! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adClick(.max, .reuse(.interstitial), adUnitID))
  }
  
  func didFail(toDisplay ad: MAAd, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.max, .reuse(.interstitial), adUnitID))
    didShowFail?()
    self.interstitialAd = nil
    load()
  }
  
  func didHide(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.max, .reuse(.interstitial), adUnitID))
    didHide?()
    self.interstitialAd = nil
    self.presentState = false
    load()
  }
  
  func didPayRevenue(for ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Did pay revenue(\(ad.revenue))!")
    LogEventManager.shared.log(event: .adPayRevenue(.max, .reuse(.interstitial), adUnitID))
    if ad.revenue != 0 {
      LogEventManager.shared.log(event: .adHadRevenue(.max, .reuse(.interstitial), adUnitID))
    }
    let adRevenueParams: [AnyHashable: Any] = [
      kAppsFlyerAdRevenueCountry: "US",
      kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
      kAppsFlyerAdRevenueAdType: "Max_Interstitial"
    ]
    
    AppsFlyerAdRevenue.shared().logAdRevenue(
      monetizationNetwork: "applovinmax",
      mediationNetwork: MediationNetworkType.applovinMax,
      eventRevenue: ad.revenue as NSNumber,
      revenueCurrency: "USD",
      additionalParameters: adRevenueParams)
  }
}

extension MaxInterstitialAd {
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
      print("[MediationAd] [AdManager] [Max] [InterstitialAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [Max] [InterstitialAd] Start load! (\(String(describing: adUnitID)))")
      if let name {
        LogEventManager.shared.log(event: .adLoadRequest(.max, name))
        TimeManager.shared.start(event: .adLoad(name))
      }
      
      self.interstitialAd = MAInterstitialAd(adUnitIdentifier: adUnitID)
      interstitialAd?.delegate = self
      interstitialAd?.revenueDelegate = self
      interstitialAd?.load()
    }
  }
}
