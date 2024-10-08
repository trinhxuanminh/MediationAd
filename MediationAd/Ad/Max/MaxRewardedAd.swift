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
    LogEventManager.shared.log(event: .adShowRequest(.max, .reuse(.rewarded), adUnitID))
    rewardedAd?.show()
  }
}

extension MaxRewardedAd: MARewardedAdDelegate, MAAdRevenueDelegate {
  func didLoad(_ ad: MAAd) {
    self.isLoading = false
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did load! (\(String(describing: adUnitID)))")
    let time = TimeManager.shared.end(event: .adLoad(.max, .reuse(.rewarded), adUnitID, nil))
    LogEventManager.shared.log(event: .adLoadSuccess(.max, .reuse(.rewarded), adUnitID, time))
    self.retryAttempt = 0
    self.didLoadSuccess?()
    
    let network = ad.networkName
    print("[MediationAd] [AdManager] [Max] [RewardAd] Adapter(\(String(describing: network)))!")
  }
  
  func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    self.isLoading = false
    self.retryAttempt += 1
    LogEventManager.shared.log(event: .adLoadRetryFail(.max, .reuse(.rewarded), adUnitID))
    self.didLoadFail?()
  }
  
  func didDisplay(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Will display! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowSuccess(.max, .reuse(.rewarded), adUnitID))
    willPresent?()
    self.presentState = true
  }
  
  func didClick(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did click! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adClick(.max, .reuse(.rewarded), adUnitID))
  }
  
  func didFail(toDisplay ad: MAAd, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did fail to show content! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowFail(.max, .reuse(.rewarded), adUnitID))
    didShowFail?()
    self.rewardedAd = nil
    load()
  }
  
  func didRewardUser(for ad: MAAd, with reward: MAReward) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did reward user! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adEarnReward(.max, .reuse(.rewarded), adUnitID))
    didEarnReward?()
  }
  
  func didHide(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did hide! (\(String(describing: adUnitID)))")
    LogEventManager.shared.log(event: .adShowHide(.max, .reuse(.rewarded), adUnitID))
    didHide?()
    self.rewardedAd = nil
    self.presentState = false
    load()
  }
  
  func didPayRevenue(for ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [RewardAd] Did pay revenue(\(ad.revenue))!")
    LogEventManager.shared.log(event: .adPayRevenue(.max, .reuse(.rewarded), adUnitID))
    if ad.revenue != 0 {
      LogEventManager.shared.log(event: .adHadRevenue(.max, .reuse(.rewarded), adUnitID))
    }
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
      print("[MediationAd] [AdManager] [Max] [RewardAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      
      self.isLoading = true
      print("[MediationAd] [AdManager] [Max] [RewardAd] Start load! (\(String(describing: adUnitID)))")
      LogEventManager.shared.log(event: .adLoadRequest(.max, .reuse(.rewarded), adUnitID))
      TimeManager.shared.start(event: .adLoad(.max, .reuse(.rewarded), adUnitID, nil))
      
      self.rewardedAd = MARewardedAd.shared(withAdUnitIdentifier: adUnitID)
      rewardedAd?.delegate = self
      rewardedAd?.revenueDelegate = self
      rewardedAd?.load()
    }
  }
}
