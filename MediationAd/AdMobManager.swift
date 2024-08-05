//
//  AdMobManager.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import FirebaseRemoteConfig
import GoogleMobileAds
import Combine
import UserMessagingPlatform

/// An ad management structure. It supports setting InterstitialAd, RewardedAd, RewardedInterstitialAd, AppOpenAd, NativeAd, BannerAd.
/// ```
/// import AdMobManager
/// ```
/// - Warning: Available for Swift 5.3, Xcode 12.5 (macOS Big Sur). Support from iOS 13.0 or newer.
public class AdMobManager {
  public static var shared = AdMobManager()
  
  enum Keys {
    static let cache = "ADMOB_CACHE"
  }
  
  public enum State {
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
    case interstitial
    case rewarded
    case rewardedInterstitial
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
  private var adMobConfig: AdMobConfig?
  private var listReuseAd: [String: AdProtocol] = [:]
  private var listNativeAd: [String: NativeAd] = [:]
  
  public func upgradePremium() {
    guard !isPremium else {
      return
    }
    self.isPremium = true
  }
  
  public func upgradeConsent() {
    guard !isConsent else {
      return
    }
    self.isConsent = true
    self.registerState = .success
  }
  
  public func register(isRelease: Bool,
                       isConsent: Bool,
                       defaultData: Data,
                       remoteData: Data?
  ) {
    self.defaultData = defaultData
    self.isRelease = isRelease
    self.isConsent = isConsent
    
    guard !isPremium else {
      print("[AdMobManager] Premium!")
      change(state: .premium)
      return
    }
    
    print("[AdMobManager] Start register!")
    LogEventManager.shared.log(event: .register)
    
    if let remoteData {
      decoding(data: remoteData)
    }
    fetchCache()
    fetchDefault()
  }
  
  public func status(type: AdType, name: String) -> Bool? {
    guard !isPremium else {
      print("[AdMobManager] Premium!")
      return nil
    }
    guard let adMobConfig else {
      print("[AdMobManager] Not yet registered!")
      return nil
    }
    guard adMobConfig.status else {
      return false
    }
    guard registerState == .success else {
      print("[AdMobManager] Can't Request Ads!")
      return nil
    }
    guard let adConfig = getAd(type: type, name: name) as? AdConfigProtocol else {
      print("[AdMobManager] Ads don't exist! (\(name))")
      return nil
    }
    if !isRelease, adConfig.isAuto == true {
      return false
    }
    return adConfig.status
  }
  
  public func load(type: Reuse,
                   name: String,
                   success: Handler? = nil,
                   fail: Handler? = nil
  ) {
    switch status(type: .reuse(type), name: name) {
    case false:
      print("[AdMobManager] Ads are not allowed to show! (\(name))")
      fail?()
      return
    case true:
      break
    default:
      fail?()
      return
    }
    guard let adConfig = getAd(type: .reuse(type), name: name) as? AdConfigProtocol else {
      print("[AdMobManager] Ads don't exist! (\(name))")
      fail?()
      return
    }
    guard listReuseAd[type.rawValue + adConfig.id] == nil else {
      fail?()
      return
    }
    
    let adProtocol: AdProtocol!
    switch type {
    case .splash:
      guard let splash = adConfig as? Splash else {
        print("[AdMobManager] Format conversion error! (\(name))")
        fail?()
        return
      }
      let splashAd = SplashAd()
      splashAd.config(timeout: splash.timeout)
      adProtocol = splashAd
    case .appOpen:
      adProtocol = AppOpenAd()
    case .interstitial:
      adProtocol = InterstitialAd()
    case .rewarded:
      adProtocol = RewardedAd()
    case .rewardedInterstitial:
      adProtocol = RewardedInterstitialAd()
    }
    adProtocol.config(didFail: fail, didSuccess: success)
    adProtocol.config(id: adConfig.id)
    self.listReuseAd[type.rawValue + adConfig.id] = adProtocol
  }
  
  public func preloadNative(name: String,
                            success: Handler? = nil,
                            fail: Handler? = nil
  ) {
    switch status(type: .onceUsed(.native), name: name) {
    case false:
      print("[AdMobManager] Ads are not allowed to show! (\(name))")
      fail?()
      return
    case true:
      break
    default:
      fail?()
      return
    }
    guard let native = getAd(type: .onceUsed(.native), name: name) as? Native else {
      print("[AdMobManager] Ads don't exist! (\(name))")
      fail?()
      return
    }
    guard native.isPreload == true else {
      print("[AdMobManager] Ads are not preloaded! (\(name))")
      fail?()
      return
    }
    guard listNativeAd[name] == nil else {
      fail?()
      return
    }
    let nativeAd = NativeAd()
    nativeAd.bind(didReceive: success, didError: fail)
    nativeAd.config(ad: native, rootViewController: nil)
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
      print("[AdMobManager] Ads are not allowed to show! (\(name))")
      didFail?()
      return
    case true:
      break
    default:
      didFail?()
      return
    }
    guard let adConfig = getAd(type: .reuse(type), name: name) as? AdConfigProtocol else {
      print("[AdMobManager] Ads don't exist! (\(name))")
      didFail?()
      return
    }
    guard let ad = listReuseAd[type.rawValue + adConfig.id] else {
      print("[AdMobManager] Ads do not exist! (\(name))")
      didFail?()
      return
    }
    guard !checkIsPresent() else {
      print("[AdMobManager] Ads display failure - other ads is showing! (\(name))")
      didFail?()
      return
    }
    guard checkFrequency(adConfig: adConfig, ad: ad) else {
      print("[AdMobManager] Ads hasn't been displayed yet! (\(name))")
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

extension AdMobManager {
  func getAd(type: AdType, name: String) -> Any? {
    guard let adMobConfig else {
      return nil
    }
    switch type {
    case .onceUsed(let type):
      switch type {
      case .banner:
        return adMobConfig.banners?.first(where: { $0.name == name })
      case .native:
        return adMobConfig.natives?.first(where: { $0.name == name })
      }
    case .reuse(let type):
      switch type {
      case .splash:
        return adMobConfig.splashs?.first(where: { $0.name == name })
      case .appOpen:
        guard
          let appOpen = adMobConfig.appOpen,
          appOpen.name == name
        else {
          return nil
        }
        return adMobConfig.appOpen
      case .interstitial:
        return adMobConfig.interstitials?.first(where: { $0.name == name })
      case .rewarded:
        return adMobConfig.rewardeds?.first(where: { $0.name == name })
      case .rewardedInterstitial:
        return adMobConfig.rewardedInterstitials?.first(where: { $0.name == name })
      }
    }
  }
  
  func getNativePreload(name: String) -> NativeAd? {
    return listNativeAd[name]
  }
}

extension AdMobManager {
  private func checkIsPresent() -> Bool {
    for ad in listReuseAd where ad.value.isPresent() {
      return true
    }
    return false
  }
  
  private func updateCache() {
    guard let adMobConfig else {
      return
    }
    guard let data = try? JSONEncoder().encode(adMobConfig) else {
      return
    }
    UserDefaults.standard.set(data, forKey: Keys.cache)
  }
  
  private func decoding(data: Data) {
    guard registerState == .wait else {
      return
    }
    guard let adMobConfig = try? JSONDecoder().decode(AdMobConfig.self, from: data) else {
      print("[AdMobManager] Invalid (AdMobConfig) format!")
      return
    }
    self.adMobConfig = adMobConfig
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
    decoding(data: cacheData)
  }
  
  private func fetchDefault() {
    guard let defaultData else {
      return
    }
    decoding(data: defaultData)
    change(state: .error)
  }
  
  private func checkFrequency(adConfig: AdConfigProtocol, ad: AdProtocol) -> Bool {
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
    self.registerState = state
  }
}
