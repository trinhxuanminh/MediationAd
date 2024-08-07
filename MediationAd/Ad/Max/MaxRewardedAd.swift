//
//  MaxRewardedAd.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 06/08/2024.
//

import UIKit
import AppLovinSDK
import AppsFlyerAdRevenue

class MaxRewardedAd: NSObject, ReuseAdProtocol {
  private var rewardedAd: MARewardedAd?
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
      print("[MediationAd] [AdManager] [Max] [RewardAd] Display failure - not ready to show! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    guard !presentState else {
      print("[MediationAd] [AdManager] [Max] [RewardAd] Display failure - ads are being displayed! (\(String(describing: adUnitID)))")
      didFail?()
      return
    }
    print("[MediationAd] [AdManager] [Max] [RewardAd] Requested to show! (\(String(describing: adUnitID)))")
    self.didShowFail = didFail
    self.willPresent = willPresent
    self.didHide = didHide
    self.didEarnReward = didEarnReward
    rewardedAd?.show()
  }
}

extension MaxRewardedAd: MARewardedAdDelegate, MAAdRevenueDelegate {
  func didLoad(_ ad: MAAd) {
    self.isLoading = false
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did load! (\(String(describing: adUnitID)))")
    self.retryAttempt = 0
    self.didLoadSuccess?()
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    self.isLoading = false
    self.retryAttempt += 1
    guard self.retryAttempt == 1 else {
      self.didLoadFail?()
      return
    }
    let delaySec = 5.0
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did fail to load. Reload after \(delaySec)s! (\(String(describing: adUnitID))) - (\(String(describing: error)))")
    DispatchQueue.global().asyncAfter(deadline: .now() + delaySec, execute: self.load)
  }
  
  func didDisplay(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Will display! (\(String(describing: adUnitID)))")
    willPresent?()
    self.presentState = true
  }
  
  func didClick(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did click! (\(String(describing: adUnitID)))")
  }
  
  func didFail(toDisplay ad: MAAd, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did fail to show content! (\(String(describing: adUnitID)))")
    didShowFail?()
    self.rewardedAd = nil
    load()
  }
  
  func didRewardUser(for ad: MAAd, with reward: MAReward) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did reward user! (\(String(describing: adUnitID)))")
    didEarnReward?()
  }
  
  func didHide(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did hide! (\(String(describing: adUnitID)))")
    didHide?()
    self.rewardedAd = nil
    self.presentState = false
    load()
  }
  
  func didPayRevenue(for ad: MAAd) {
    let adRevenueParams: [AnyHashable: Any] = [
      kAppsFlyerAdRevenueCountry: "US",
      kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
      kAppsFlyerAdRevenueAdType: "Max_Rewarded"
    ]
    
    AppsFlyerAdRevenue.shared().logAdRevenue(
      monetizationNetwork: "applovinmax",
      mediationNetwork: MediationNetworkType.applovinMax,
      eventRevenue: ad.revenue as NSNumber,
      revenueCurrency: "USD",
      additionalParameters: adRevenueParams)
  }
}

extension MaxRewardedAd {
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
      print("[MediationAd] [AdManager] [Max] [RewardAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [Max] [RewardAd] Start load! (\(String(describing: adUnitID)))")
      
      self.rewardedAd = MARewardedAd.shared(withAdUnitIdentifier: adUnitID)
      rewardedAd?.delegate = self
      rewardedAd?.revenueDelegate = self
      rewardedAd?.load()
    }
  }
}
