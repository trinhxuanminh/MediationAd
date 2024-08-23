//
//  RewardedInterstitialAd.swift
//  
//
//  Created by Trịnh Xuân Minh on 05/12/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobRewardedInterstitialAd: NSObject, ReuseAdProtocol {
  private var rewardedInterstitialAd: GADRewardedInterstitialAd?
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
    return rewardedInterstitialAd != nil
  }
  
  func show(rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard isReady() else {
      print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.admob, .reuse(.rewardedInterstitial), adUnitID))
    rewardedInterstitialAd?.present(fromRootViewController: rootViewController, userDidEarnRewardHandler: { [weak self] in
      guard let self else {
        return
      }
      LogEventManager.shared.log(event: .adEarnReward(.admob, .reuse(.rewardedInterstitial), adUnitID))
      self.didEarnReward?()
    })
  }
}

extension AdMobRewardedInterstitialAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.admob, .reuse(.rewardedInterstitial), adUnitID))
    didShowFail?()
    self.rewardedInterstitialAd = nil
    load()
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.admob, .reuse(.rewardedInterstitial), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.admob, .reuse(.rewardedInterstitial), adUnitID))
    didHide?()
    self.rewardedInterstitialAd = nil
    self.presentState = false
    load()
  }
}

extension AdMobRewardedInterstitialAd {
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
      print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.admob, .reuse(.rewardedInterstitial), adUnitID))
      TimeManager.shared.start(event: .adLoad(.admob, .reuse(.rewardedInterstitial), adUnitID, nil))
      
      let request = GADRequest()
      GADRewardedInterstitialAd.load(
        withAdUnitID: adUnitID,
        request: request
      ) { [weak self] (ad, error) in
        guard let self else {
          return
        }
        self.isLoading = false
        guard error == nil, let ad = ad else {
          self.retryAttempt += 1
          guard self.retryAttempt == 1 else {
            LogEventManager.shared.log(event: .adLoadRetryFail(.admob, .reuse(.rewardedInterstitial), adUnitID))
            self.didLoadFail?()
            return
          }
          LogEventManager.shared.log(event: .adLoadFail(.admob, .reuse(.rewardedInterstitial), adUnitID))
          let delaySec = 5.0
          print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did fail to load. Reload after \(delaySec)s! (\(String(describing: adUnitID))) - (\(String(describing: error)))")
          DispatchQueue.global().asyncAfter(deadline: .now() + delaySec, execute: self.load)
          return
        }
        print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did load! (\(String(describing: adUnitID)))")
        let time = TimeManager.shared.end(event: .adLoad(.admob, .reuse(.rewardedInterstitial), adUnitID, nil))
        LogEventManager.shared.log(event: .adLoadSuccess(.admob, .reuse(.rewardedInterstitial), adUnitID, time))
        self.retryAttempt = 0
        self.rewardedInterstitialAd = ad
        self.rewardedInterstitialAd?.fullScreenContentDelegate = self
        self.didLoadSuccess?()
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Adapter(\(String(describing: network)))!")
        
        ad.paidEventHandler = { adValue in
          print("[MediationAd] [AdManager] [AdMob] [RewardedInterstitialAd] Did pay revenue(\(adValue.value))!")
          LogEventManager.shared.log(event: .adPayRevenue(.admob, .reuse(.rewardedInterstitial), adUnitID))
          if adValue.value != 0 {
            LogEventManager.shared.log(event: .adHadRevenue(.admob, .reuse(.rewardedInterstitial), adUnitID))
          }
          let adRevenueParams: [AnyHashable: Any] = [
            kAppsFlyerAdRevenueCountry: "US",
            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
            kAppsFlyerAdRevenueAdType: "AdMob_RewardedInterstitial"
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
