//
//  SplashAd.swift
//  
//
//  Created by Trịnh Xuân Minh on 06/09/2023.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobSplashAd: NSObject, ReuseAdProtocol {
  private var splashAd: GADInterstitialAd?
  private var adUnitID: String?
  private var placement: String?
  private var name: String?
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
  
  func config(id: String, name: String) {
    self.adUnitID = id
    self.name = name
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
  
  func show(placement: String,
            rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard !presentState else {
      print("[MediationAd] [AdManager] [AdMob] [SplashAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard isExist() else {
      print("[MediationAd] [AdManager] [AdMob] [SplashAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [SplashAd] Requested to show! (\(String(describing: adUnitID)))")
    self.placement = placement
    self.didFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.admob, .reuse(.splash), adUnitID))
    splashAd?.present(fromRootViewController: rootViewController)
  }
}

extension AdMobSplashAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("[MediationAd] [AdManager] [AdMob] [SplashAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.admob, .reuse(.splash), adUnitID))
    didFail?()
    self.splashAd = nil
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [SplashAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.admob, .reuse(.splash), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [SplashAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.admob, .reuse(.splash), adUnitID))
    didHide?()
    self.presentState = false
    self.splashAd = nil
  }
}

extension AdMobSplashAd {
  private func load() {
    guard !isLoading else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [AdMob] [SplashAd] Failed to load - not initialized yet! Please install ID.")
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
          print("[MediationAd] [AdManager] [AdMob] [SplashAd] Load fail (\(String(describing: adUnitID))) - timeout!")
          LogEventManager.shared.log(event: .adLoadTimeout(.admob, .reuse(.splash), adUnitID))
          didLoadFail?()
        })
      }
      
      print("[MediationAd] [AdManager] [AdMob] [SplashAd] Start load! (\(String(describing: adUnitID)))")
      if let name {
        LogEventManager.shared.log(event: .adLoadRequest(.admob, name))
        TimeManager.shared.start(event: .adLoad(name))
      }
      
      let request = GADRequest()
      GADInterstitialAd.load(
        withAdUnitID: adUnitID,
        request: request
      ) { [weak self] (ad, error) in
        guard let self else {
          return
        }
        guard !didResponse else {
          return
        }
        self.didResponse = true
        guard error == nil, let ad = ad else {
          print("[MediationAd] [AdManager] [AdMob] [SplashAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
          LogEventManager.shared.log(event: .adLoadFail(.admob, .reuse(.splash), adUnitID))
          self.didLoadFail?()
          return
        }
        print("[MediationAd] [AdManager] [AdMob] [SplashAd] Did load! (\(String(describing: adUnitID)))")
        if let name {
          let time = TimeManager.shared.end(event: .adLoad(name))
          LogEventManager.shared.log(event: .adLoadSuccess(.admob, name, time))
        }
        self.splashAd = ad
        self.splashAd?.fullScreenContentDelegate = self
        self.didLoadSuccess?()
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        print("[MediationAd] [AdManager] [AdMob] [SplashAd] Adapter(\(String(describing: network)))!")
        
        ad.paidEventHandler = { adValue in
          print("[MediationAd] [AdManager] [AdMob] [SplashAd] Did pay revenue(\(adValue.value))!")
          LogEventManager.shared.log(event: .adPayRevenue(.admob, .reuse(.splash), adUnitID))
          if adValue.value != 0 {
            LogEventManager.shared.log(event: .adHadRevenue(.admob, .reuse(.splash), adUnitID))
          }
          let adRevenueParams: [AnyHashable: Any] = [
            kAppsFlyerAdRevenueCountry: "US",
            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
            kAppsFlyerAdRevenueAdType: "AdMob_Interstitial_Splash"
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
