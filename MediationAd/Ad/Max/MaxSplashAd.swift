//
//  MaxSplashAd.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 06/08/2024.
//

import UIKit
import AppLovinSDK
import AppsFlyerAdRevenue

class MaxSplashAd: NSObject, ReuseAdProtocol {
  private var splashAd: MAInterstitialAd?
  private var adUnitID: String?
  private var presentState = false
  private var isLoading = false
  private var timeout: Double?
  private var time = 0.0
  private var timer: Timer?
  private var timeInterval = 0.1
  private var didLoadFail: Handler?
  private var didLoadSuccess: Handler?
  private var didFail: Handler?
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
  
  func config(timeout: Double) {
    self.timeout = timeout
  }
  
  func isPresent() -> Bool {
    return presentState
  }
  
  func isExist() -> Bool {
    return splashAd != nil
  }
  
  func show(rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard isExist() else {
      print("[MediationAd] [AdManager] [Max] [SplashAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [Max] [SplashAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [Max] [SplashAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.max, .reuse(.splash), adUnitID))
    splashAd?.show()
  }
}

extension MaxSplashAd: MAAdDelegate, MAAdRevenueDelegate {
  func didLoad(_ ad: MAAd) {
    guard let timeout, self.time < timeout else {
      return
    }
    print("[MediationAd] [AdManager] [Max] [SplashAd] Did load! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adLoadSuccess(.max, .reuse(.splash), adUnitID))
    self.invalidate()
    self.didLoadSuccess?()
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    guard let timeout, self.time < timeout else {
      return
    }
    print("[MediationAd] [AdManager] [Max] [SplashAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    LogEventManager.shared.log(event: .adLoadFail(.max, .reuse(.splash), adUnitID))
    self.invalidate()
    self.didLoadFail?()
  }
  
  func didDisplay(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [SplashAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.max, .reuse(.splash), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func didClick(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [SplashAd] Did click! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adClick(.max, .reuse(.splash), adUnitID))
  }
  
  func didFail(toDisplay ad: MAAd, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [SplashAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.max, .reuse(.splash), adUnitID))
    didFail?()
    self.splashAd = nil
  }
  
  func didHide(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [SplashAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.max, .reuse(.splash), adUnitID))
    didHide?()
    self.presentState = false
    self.splashAd = nil
  }
  
  func didPayRevenue(for ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [SplashAd] Did pay revenue(\(ad.revenue))!")
    LogEventManager.shared.log(event: .adPayRevenue(.max, .reuse(.splash), adUnitID))
    if ad.revenue != 0 {
      LogEventManager.shared.log(event: .adHadRevenue(.max, .reuse(.splash), adUnitID))
    }
    let adRevenueParams: [AnyHashable: Any] = [
      kAppsFlyerAdRevenueCountry: "US",
      kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
      kAppsFlyerAdRevenueAdType: "Max_Interstitial_Splash"
    ]
    
    AppsFlyerAdRevenue.shared().logAdRevenue(
      monetizationNetwork: "applovinmax",
      mediationNetwork: MediationNetworkType.applovinMax,
      eventRevenue: ad.revenue as NSNumber,
      revenueCurrency: "USD",
      additionalParameters: adRevenueParams)
  }
}

extension MaxSplashAd {
  private func load() {
    guard !isLoading else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [Max] [SplashAd] Failed to load - not initialized yet! Please install ID.")
      didLoadFail?()
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      self.fire()
      print("[MediationAd] [AdManager] [Max] [SplashAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.max, .reuse(.splash), adUnitID))
      
      self.splashAd = MAInterstitialAd(adUnitIdentifier: adUnitID)
      splashAd?.delegate = self
      splashAd?.revenueDelegate = self
      splashAd?.load()
    }
  }
  
  private func fire() {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval,
                                        target: self,
                                        selector: #selector(self.isReady),
                                        userInfo: nil,
                                        repeats: true)
    }
  }
  
  private func invalidate() {
    self.timer?.invalidate()
    self.timer = nil
  }
  
  @objc private func isReady() {
    self.time += timeInterval
    
    if let timeout = timeout, time < timeout {
      return
    }
    print("[MediationAd] [AdManager] [Max] [SplashAd] Load fail (\(String(describing: adUnitID))) - timeout!")
    LogEventManager.shared.log(event: .adLoadTimeout(.max, .reuse(.splash), adUnitID))
    invalidate()
    didLoadFail?()
  }
}
