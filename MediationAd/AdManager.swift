//
//  AdManager.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import FirebaseRemoteConfig
import GoogleMobileAds
import Combine
import UserMessagingPlatform
import AppLovinSDK

public class AdManager {
  public static var shared = AdManager()
  
  enum Keys {
    static let cache = "AD_CACHE"
  }
  
  enum Resource: String {
    case remote
    case cache
    case local
  }
  
  public enum State: String {
    case wait
    case success
    case premium
    case reject
    case error
  }
  
  public enum OnceUsed: String {
    case native
    case banner
  }
  
  public enum Reuse: String {
    case splash
    case appOpen
    case interstitial = "inter"
    case rewarded = "reward"
    case rewardedInterstitial = "re_inter"
  }
  
  public enum AdType {
    case onceUsed(_ type: OnceUsed)
    case reuse(_ type: Reuse)
  }
  
  @Published public private(set) var registerState: State = .wait
  private var isPremium = false
  private var isRelease = true
  private var isConsent = true
  private var defaultData: Data?
  private var adConfig: AdConfig?
  private var listReuseAd: [String: ReuseAdProtocol] = [:]
  private var listNativeAd: [String: OnceUsedAdProtocol] = [:]
  
  public func upgradePremium() {
    guard !isPremium else {
      return
    }
    print("[MediationAd] [AdManager] Upgrade premium!")
    self.isPremium = true
  }
  
  public func upgradeConsent() {
    guard !isConsent else {
      return
    }
    print("[MediationAd] [AdManager] Upgrade consent!")
    self.isConsent = true
    self.registerState = .success
  }
  
  public func activeDebug() {
    ALSdk.shared().showMediationDebugger()
  }
  
  public func register(isRelease: Bool,
                       isConsent: Bool,
                       defaultData: Data,
                       remoteData: Data
  ) {
    guard registerState == .wait else {
      return
    }
    self.defaultData = defaultData
    self.isRelease = isRelease
    self.isConsent = isConsent
    
    guard !isPremium else {
      print("[MediationAd] [AdManager] Premium!")
      change(state: .premium)
      return
    }
    
    print("[MediationAd] [AdManager] Start register!")
    LogEventManager.shared.log(event: .adManagerStartRegister)
    
    decoding(data: remoteData, resource: .remote)
    fetchCache()
    fetchDefault()
  }
  
  public func status(type: AdType, name: String) -> Bool? {
    guard !isPremium else {
      print("[MediationAd] [AdManager] Premium!")
      return nil
    }
    guard let adConfig else {
      print("[MediationAd] [AdManager] Not yet registered!")
      return nil
    }
    guard adConfig.status else {
      return false
    }
    guard registerState == .success else {
      print("[MediationAd] [AdManager] Can't Request Ads!")
      return nil
    }
    guard let adConfig = getAd(type: type, name: name) as? AdConfigProtocol else {
      print("[MediationAd] [AdManager] Ads don't exist! (\(name))")
      return nil
    }
    if !isRelease, adConfig.isAuto == true {
      return false
    }
    return adConfig.status
  }
  
  public func network(type: AdType, name: String) -> MonetizationNetwork? {
    guard let adConfig = getAd(type: type, name: name) as? AdConfigProtocol else {
      print("[MediationAd] [AdManager] Ads don't exist! (\(name))")
      return nil
    }
    return adConfig.network
  }
  
  public func load(type: Reuse,
                   name: String,
                   success: Handler? = nil,
                   fail: Handler? = nil
  ) {
    switch status(type: .reuse(type), name: name) {
    case false:
      print("[MediationAd] [AdManager] Ads are not allowed to show! (\(name))")
      fail?()
      return
    case true:
      break
    default:
      fail?()
      return
    }
    guard let adConfig = getAd(type: .reuse(type), name: name) as? AdConfigProtocol else {
      print("[MediationAd] [AdManager] Ads don't exist! (\(name))")
      fail?()
      return
    }
    guard listReuseAd[type.rawValue + adConfig.id] == nil else {
      fail?()
      return
    }
    
    let adProtocol: ReuseAdProtocol!
    
    switch adConfig.network {
    case .admob:
      switch type {
      case .splash:
        guard let splash = adConfig as? Splash else {
          print("[MediationAd] [AdManager] Format conversion error! (\(name))")
          fail?()
          return
        }
        let splashAd = AdMobSplashAd()
        splashAd.config(timeout: splash.timeout)
        adProtocol = splashAd
      case .appOpen:
        adProtocol = AdMobAppOpenAd()
      case .interstitial:
        adProtocol = AdMobInterstitialAd()
      case .rewarded:
        adProtocol = AdMobRewardedAd()
      case .rewardedInterstitial:
        adProtocol = AdMobRewardedInterstitialAd()
      }
    case .max:
      switch type {
      case .splash:
        guard let splash = adConfig as? Splash else {
          print("[MediationAd] [AdManager] Format conversion error! (\(name))")
          fail?()
          return
        }
        let splashAd = MaxSplashAd()
        splashAd.config(timeout: splash.timeout)
        adProtocol = splashAd
      case .appOpen:
        adProtocol = MaxAppOpenAd()
      case .interstitial:
        adProtocol = MaxInterstitialAd()
      case .rewarded:
        adProtocol = MaxRewardedAd()
      case .rewardedInterstitial:
        print("[MediationAd] [AdManager] This type of ads is not supported! (\(name))")
        fail?()
        return
      }
    }
    
    adProtocol.config(didFail: fail, didSuccess: success)
    adProtocol.config(id: adConfig.id)
    self.listReuseAd[type.rawValue + adConfig.id] = adProtocol
  }
  
  public func preloadNative(name: String,
                            into nativeAdView: UIView? = nil,
                            success: Handler? = nil,
                            fail: Handler? = nil
  ) {
    switch status(type: .onceUsed(.native), name: name) {
    case false:
      print("[MediationAd] [AdManager] Ads are not allowed to show! (\(name))")
      fail?()
      return
    case true:
      break
    default:
      fail?()
      return
    }
    guard let native = getAd(type: .onceUsed(.native), name: name) as? Native else {
      print("[MediationAd] [AdManager] Ads don't exist! (\(name))")
      fail?()
      return
    }
    guard native.isPreload == true else {
      print("[MediationAd] [AdManager] Ads are not preloaded! (\(name))")
      fail?()
      return
    }
    guard listNativeAd[name] == nil else {
      fail?()
      return
    }
    let nativeAd: OnceUsedAdProtocol!
    
    switch native.network {
    case .admob:
      nativeAd = AdMobNativeAd()
    case .max:
      nativeAd = MaxNativeAd()
    }
    
    nativeAd.bind(didReceive: success, didError: fail)
    nativeAd.config(ad: native,
                    rootViewController: nil,
                    into: nativeAdView)
    
    self.listNativeAd[name] = nativeAd
  }
  
  public func show(type: Reuse,
                   name: String,
                   rootViewController: UIViewController,
                   didFail: Handler?,
                   willPresent: Handler? = nil,
                   didEarnReward: Handler? = nil,
                   didHide: Handler?
  ) {
    switch status(type: .reuse(type), name: name) {
    case false:
      print("[MediationAd] [AdManager] Ads are not allowed to show! (\(name))")
      didFail?()
      return
    case true:
      break
    default:
      didFail?()
      return
    }
    guard let adConfig = getAd(type: .reuse(type), name: name) as? AdConfigProtocol else {
      print("[MediationAd] [AdManager] Ads don't exist! (\(name))")
      didFail?()
      return
    }
    guard let ad = listReuseAd[type.rawValue + adConfig.id] else {
      print("[MediationAd] [AdManager] Ads do not exist! (\(name))")
      didFail?()
      return
    }
    guard !checkIsPresent() else {
      print("[MediationAd] [AdManager] Ads display failure - other ads is showing! (\(name))")
      didFail?()
      return
    }
    guard checkFrequency(adConfig: adConfig, ad: ad) else {
      print("[MediationAd] [AdManager] Ads hasn't been displayed yet! (\(name))")
      didFail?()
      return
    }
    ad.show(rootViewController: rootViewController,
            didFail: didFail,
            willPresent: willPresent,
            didEarnReward: didEarnReward,
            didHide: didHide)
  }
}

extension AdManager {
  func getAd(type: AdType, name: String) -> Any? {
    guard let adConfig else {
      return nil
    }
    switch type {
    case .onceUsed(let type):
      switch type {
      case .banner:
        return adConfig.banners?.first(where: { $0.name == name })
      case .native:
        return adConfig.natives?.first(where: { $0.name == name })
      }
    case .reuse(let type):
      switch type {
      case .splash:
        return adConfig.splashs?.first(where: { $0.name == name })
      case .appOpen:
        return adConfig.appOpens?.first(where: { $0.name == name })
      case .interstitial:
        return adConfig.interstitials?.first(where: { $0.name == name })
      case .rewarded:
        return adConfig.rewardeds?.first(where: { $0.name == name })
      case .rewardedInterstitial:
        return adConfig.rewardedInterstitials?.first(where: { $0.name == name })
      }
    }
  }
  
  func getNativePreload(name: String) -> OnceUsedAdProtocol? {
    return listNativeAd[name]
  }
}

extension AdManager {
  private func checkIsPresent() -> Bool {
    for ad in listReuseAd where ad.value.isPresent() {
      return true
    }
    return false
  }
  
  private func updateCache() {
    guard let adConfig else {
      return
    }
    guard let data = try? JSONEncoder().encode(adConfig) else {
      return
    }
    UserDefaults.standard.set(data, forKey: Keys.cache)
  }
  
  private func decoding(data: Data, resource: Resource) {
    guard registerState == .wait else {
      return
    }
    guard let adConfig = try? JSONDecoder().decode(AdConfig.self, from: data) else {
      print("[MediationAd] [AdManager] Invalid (AdMobConfig) format - \(resource.rawValue.capitalized)!")
      switch resource {
      case .remote:
        LogEventManager.shared.log(event: .adManagerRemoteInvaidFormat)
      case .cache:
        LogEventManager.shared.log(event: .adManagerLocalInvaidFormat)
      case .local:
        LogEventManager.shared.log(event: .adManagerCacheInvaidFormat)
      }
      return
    }
    
    self.adConfig = adConfig
    updateCache()
    
    if isConsent {
      change(state: .success)
    } else {
      change(state: .reject)
    }
  }
  
  private func fetchCache() {
    guard let cacheData = UserDefaults.standard.data(forKey: Keys.cache) else {
      return
    }
    decoding(data: cacheData, resource: .cache)
  }
  
  private func fetchDefault() {
    guard let defaultData else {
      return
    }
    decoding(data: defaultData, resource: .local)
    change(state: .error)
  }
  
  private func checkFrequency(adConfig: AdConfigProtocol, ad: ReuseAdProtocol) -> Bool {
    guard
      let interstitial = adConfig as? Interstitial,
      let start = interstitial.start,
      let frequency = interstitial.frequency
    else {
      return true
    }
    let countClick = FrequencyManager.shared.getCount(name: adConfig.name) + 1
    guard countClick >= start else {
      FrequencyManager.shared.increaseCount(name: adConfig.name)
      return false
    }
    let isShow = (countClick - start) % frequency == 0
    if !isShow || ad.isExist!() {
      FrequencyManager.shared.increaseCount(name: adConfig.name)
    }
    return isShow
  }
  
  private func change(state: State) {
    guard registerState == .wait else {
      return
    }
    print("[MediationAd] [AdManager] register \(state)!")
    self.registerState = state
    
    switch state {
    case .success:
      LogEventManager.shared.log(event: .adManagerSuccess)
    case .premium:
      LogEventManager.shared.log(event: .adManagerPremium)
    case .reject:
      LogEventManager.shared.log(event: .adManagerReject)
    case .error:
      LogEventManager.shared.log(event: .adManagerError)
    default:
      break
    }
  }
}
