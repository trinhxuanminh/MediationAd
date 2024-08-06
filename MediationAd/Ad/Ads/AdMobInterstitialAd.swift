//
//  InterstitialAd.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobInterstitialAd: NSObject, ReuseAdProtocol {
  private var interstitialAd: GADInterstitialAd?
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
      print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    interstitialAd?.present(fromRootViewController: rootViewController)
  }
}

extension AdMobInterstitialAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Did fail to show content! (\(String(describing: adUnitID)))")
    didShowFail?()
    self.interstitialAd = nil
    load()
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Will display! (\(String(describing: adUnitID)))")
    willPresent?()
    self.presentState = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Did hide! (\(String(describing: adUnitID)))")
    didHide?()
    self.interstitialAd = nil
    self.presentState = false
    load()
  }
}

extension AdMobInterstitialAd {
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
    
    guard let adUnitID = adUnitID else {
      print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Start load! (\(String(describing: adUnitID)))")
      
      let request = GADRequest()
      GADInterstitialAd.load(
        withAdUnitID: adUnitID,
        request: request
      ) { [weak self] (ad, error) in
        guard let self = self else {
          return
        }
        self.isLoading = false
        guard error == nil, let ad = ad else {
          self.retryAttempt += 1
          guard self.retryAttempt == 1 else {
            self.didLoadFail?()
            return
          }
          let delaySec = 5.0
          print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Did fail to load. Reload after \(delaySec)s! (\(String(describing: adUnitID))) - (\(String(describing: error)))")
          DispatchQueue.global().asyncAfter(deadline: .now() + delaySec, execute: self.load)
          return
        }
        print("[MediationAd] [AdManager] [AdMob] [InterstitialAd] Did load! (\(String(describing: adUnitID)))")
        self.retryAttempt = 0
        self.interstitialAd = ad
        self.interstitialAd?.fullScreenContentDelegate = self
        self.didLoadSuccess?()
        
        ad.paidEventHandler = { adValue in
          let adRevenueParams: [AnyHashable: Any] = [
            kAppsFlyerAdRevenueCountry: "US",
            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
            kAppsFlyerAdRevenueAdType: "AdMob_Interstitial"
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
