//
//  AppOpenAd.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobAppOpenAd: NSObject, ReuseAdProtocol {
  private var appOpenAd: GADAppOpenAd?
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
      print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.admob, .reuse(.appOpen), adUnitID))
    appOpenAd?.present(fromRootViewController: rootViewController)
  }
}

extension AdMobAppOpenAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.admob, .reuse(.appOpen), adUnitID))
    didShowFail?()
    self.appOpenAd = nil
    load()
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.admob, .reuse(.appOpen), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.admob, .reuse(.appOpen), adUnitID))
    didHide?()
    self.appOpenAd = nil
    self.presentState = false
    load()
  }
}

extension AdMobAppOpenAd {
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
      print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.admob, .reuse(.appOpen), adUnitID))
      TimeManager.shared.start(event: .adLoad(.admob, .reuse(.appOpen), adUnitID, nil))
      
      let request = GADRequest()
      GADAppOpenAd.load(
        withAdUnitID: adUnitID,
        request: request
      ) { [weak self] (ad, error) in
        guard let self else {
          return
        }
        self.isLoading = false
        guard error == nil, let ad = ad else {
          print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
          self.retryAttempt += 1
          self.didLoadFail?()
          LogEventManager.shared.log(event: .adLoadFail(.admob, .reuse(.appOpen), adUnitID))
          return
        }
        print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Did load! (\(String(describing: adUnitID)))")
        let time = TimeManager.shared.end(event: .adLoad(.admob, .reuse(.appOpen), adUnitID, nil))
        LogEventManager.shared.log(event: .adLoadSuccess(.admob, .reuse(.appOpen), adUnitID, time))
        self.retryAttempt = 0
        self.appOpenAd = ad
        self.appOpenAd?.fullScreenContentDelegate = self
        self.didLoadSuccess?()
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Adapter(\(String(describing: network)))!")
        
        ad.paidEventHandler = { adValue in
          print("[MediationAd] [AdManager] [AdMob] [AppOpenAd] Did pay revenue(\(adValue.value))!")
          LogEventManager.shared.log(event: .adPayRevenue(.admob, .reuse(.appOpen), adUnitID))
          if adValue.value != 0 {
            LogEventManager.shared.log(event: .adHadRevenue(.admob, .reuse(.appOpen), adUnitID))
          }
          let adRevenueParams: [AnyHashable: Any] = [
            kAppsFlyerAdRevenueCountry: "US",
            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
            kAppsFlyerAdRevenueAdType: "AdMob_AppOpen"
          ]
  
          AppsFlyerAdRevenue.shared().logAdRevenue(
            monetizationNetwork: "admob",
            mediationNetwork: MediationNetworkType.googleAdMob,
            eventRevenue: adValue.value,
            revenueCurrency: adValue.currencyCode,
            additionalParameters: adRevenueParams)
        }
      }
    }
  }
}
