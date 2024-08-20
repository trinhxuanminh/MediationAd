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
  private var didResponse = false
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
    guard !didResponse else {
      return
    }
    self.didResponse = true
    print("[MediationAd] [AdManager] [Max] [SplashAd] Did load! (\(String(describing: adUnitID)))")
    let time = TimeManager.shared.end(event: .adLoad(.max, .reuse(.splash), adUnitID, nil))
    LogEventManager.shared.log(event: .adLoadSuccess(.max, .reuse(.splash), adUnitID, time))
    self.didLoadSuccess?()
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    guard !didResponse else {
      return
    }
    self.didResponse = true
    print("[MediationAd] [AdManager] [Max] [SplashAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    LogEventManager.shared.log(event: .adLoadFail(.max, .reuse(.splash), adUnitID))
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
      
      if let timeout {
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: { [weak self] in
          guard let self else {
            return
          }
          guard !didResponse else {
            return
          }
          self.didResponse = true
          print("[MediationAd] [AdManager] [Max] [SplashAd] Load fail (\(String(describing: adUnitID))) - timeout!")
          LogEventManager.shared.log(event: .adLoadTimeout(.max, .reuse(.splash), adUnitID))
          didLoadFail?()
        })
      }
      
      print("[MediationAd] [AdManager] [Max] [SplashAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.max, .reuse(.splash), adUnitID))
      TimeManager.shared.start(event: .adLoad(.max, .reuse(.splash), adUnitID, nil))
      
      self.splashAd = MAInterstitialAd(adUnitIdentifier: adUnitID)
      splashAd?.delegate = self
      splashAd?.revenueDelegate = self
      splashAd?.load()
    }
  }
}
