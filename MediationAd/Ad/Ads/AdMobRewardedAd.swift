//
//  RewardedAd.swift
//  
//
//  Created by Trịnh Xuân Minh on 02/12/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobRewardedAd: NSObject, ReuseAdProtocol {
  private var rewardedAd: GADRewardedAd?
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
    return rewardedAd != nil
  }
  
  func show(rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?
  ) {
    guard isReady() else {
      print("[MediationAd] [AdManager] [AdMob] [RewardAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [AdMob] [RewardAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [RewardAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    LogEventManager.shared.log(event: .adShowRequest(.admob, .reuse(.rewarded), adUnitID))
    rewardedAd?.present(fromRootViewController: rootViewController, userDidEarnRewardHandler: { [weak self] in
      guard let self else {
        return
      }
      LogEventManager.shared.log(event: .adEarnReward(.admob, .reuse(.rewarded), adUnitID))
      self.didEarnReward?()
    })
  }
}

extension AdMobRewardedAd: GADFullScreenContentDelegate {
  func ad(_ ad: GADFullScreenPresentingAd,
          didFailToPresentFullScreenContentWithError error: Error
  ) {
    print("[MediationAd] [AdManager] [AdMob] [RewardAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.admob, .reuse(.rewarded), adUnitID))
    didShowFail?()
    self.rewardedAd = nil
    load()
  }
  
  func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [RewardAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.admob, .reuse(.rewarded), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
    print("[MediationAd] [AdManager] [AdMob] [RewardAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.admob, .reuse(.rewarded), adUnitID))
    didHide?()
    self.rewardedAd = nil
    self.presentState = false
    load()
  }
}

extension AdMobRewardedAd {
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
      print("[MediationAd] [AdManager] [AdMob] [RewardAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [AdMob] [RewardAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.admob, .reuse(.rewarded), adUnitID))
      TimeManager.shared.start(event: .adLoad(.admob, .reuse(.rewarded), adUnitID, nil))
      
      let request = GADRequest()
      GADRewardedAd.load(
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
            LogEventManager.shared.log(event: .adLoadRetryFail(.admob, .reuse(.rewarded), adUnitID))
            self.didLoadFail?()
            return
          }
          LogEventManager.shared.log(event: .adLoadFail(.admob, .reuse(.rewarded), adUnitID))
          let delaySec = 5.0
          print("[MediationAd] [AdManager] [AdMob] [RewardAd] Did fail to load. Reload after \(delaySec)s! (\(String(describing: adUnitID))) - (\(String(describing: error)))")
          DispatchQueue.global().asyncAfter(deadline: .now() + delaySec, execute: self.load)
          return
        }
        print("[MediationAd] [AdManager] [AdMob] [RewardAd] Did load! (\(String(describing: adUnitID)))")
        let time = TimeManager.shared.end(event: .adLoad(.admob, .reuse(.rewarded), adUnitID, nil))
        LogEventManager.shared.log(event: .adLoadSuccess(.admob, .reuse(.rewarded), adUnitID, time))
        self.retryAttempt = 0
        self.rewardedAd = ad
        self.rewardedAd?.fullScreenContentDelegate = self
        self.didLoadSuccess?()
        
        let network = ad.responseInfo.adNetworkInfoArray.first
        print("[MediationAd] [AdManager] [AdMob] [RewardAd] Adapter(\(String(describing: network)))!")
        
        ad.paidEventHandler = { adValue in
          print("[MediationAd] [AdManager] [AdMob] [RewardAd] Did pay revenue(\(adValue.value))!")
          LogEventManager.shared.log(event: .adPayRevenue(.admob, .reuse(.rewarded), adUnitID))
          if adValue.value != 0 {
            LogEventManager.shared.log(event: .adHadRevenue(.admob, .reuse(.rewarded), adUnitID))
          }
          let adRevenueParams: [AnyHashable: Any] = [
            kAppsFlyerAdRevenueCountry: "US",
            kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
            kAppsFlyerAdRevenueAdType: "AdMob_Rewarded"
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
