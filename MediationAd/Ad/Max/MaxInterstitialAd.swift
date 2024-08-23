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
    return interstitialAd != nil
  }
  
  func show(rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard isReady() else {
      print("[MediationAd] [AdManager] [Max] [InterstitialAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [Max] [InterstitialAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Requested to show! (\(String(describing: adUnitID)))")
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
    let time = TimeManager.shared.end(event: .adLoad(.max, .reuse(.interstitial), adUnitID, nil))
    LogEventManager.shared.log(event: .adLoadSuccess(.max, .reuse(.interstitial), adUnitID, time))
    self.isLoading = false
    self.retryAttempt = 0
    self.didLoadSuccess?()
    
    let network = ad.networkName
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Adapter(\(String(describing: network)))!")
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    self.isLoading = false
    self.retryAttempt += 1
    guard self.retryAttempt == 1 else {
      LogEventManager.shared.log(event: .adLoadRetryFail(.max, .reuse(.interstitial), adUnitID))
      self.didLoadFail?()
      return
    }
    LogEventManager.shared.log(event: .adLoadFail(.max, .reuse(.interstitial), adUnitID))
    let delaySec = 5.0
    print("[MediationAd] [AdManager] [Max] [InterstitialAd] Did fail to load. Reload after \(delaySec)s! (\(String(describing: adUnitID))) - (\(String(describing: error)))")
    DispatchQueue.global().asyncAfter(deadline: .now() + delaySec, execute: self.load)
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
    if !isExist(), retryAttempt >= 2 {
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
      LogEventManager.shared.log(event: .adLoadRequest(.max, .reuse(.interstitial), adUnitID))
      TimeManager.shared.start(event: .adLoad(.max, .reuse(.interstitial), adUnitID, nil))
      
      self.interstitialAd = MAInterstitialAd(adUnitIdentifier: adUnitID)
      interstitialAd?.delegate = self
      interstitialAd?.revenueDelegate = self
      interstitialAd?.load()
    }
  }
}
