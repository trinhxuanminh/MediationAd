//
//  NativeAd.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

class AdMobNativeAd: NSObject, OnceUsedAdProtocol {
  enum State {
    case wait
    case loading
    case receive
    case error
  }
  
  private var nativeAd: GADNativeAd?
  private var adLoader: GADAdLoader?
  private weak var rootViewController: UIViewController?
  private var adUnitID: String?
  private var placement: String?
  private var isFullScreen = false
  private var timeout: Double?
  private var state: State = .wait
  private var didReceive: Handler?
  private var didError: Handler?
  
  func config(ad: Native, rootViewController: UIViewController?, into nativeAdView: UIView?) {
    self.rootViewController = rootViewController
    guard ad.status else {
      return
    }
    guard adUnitID == nil else {
      return
    }
    self.adUnitID = ad.id
    self.placement = ad.placement
    self.timeout = ad.timeout
    if let isFullScreen = ad.isFullScreen {
      self.isFullScreen = isFullScreen
    }
    self.load()
  }
  
  func getState() -> State {
    return state
  }
  
  func getAd() -> GADNativeAd? {
    return nativeAd
  }
  
  func bind(didReceive: Handler?, didError: Handler?) {
    self.didReceive = didReceive
    self.didError = didError
  }
}

extension AdMobNativeAd: GADNativeAdLoaderDelegate {
  func adLoader(_ adLoader: GADAdLoader,
                didFailToReceiveAdWithError error: Error) {
    guard state == .loading else {
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [NativeAd] Load fail (\(String(describing: placement))) - \(String(describing: error))!")
    if let placement {
      LogEventManager.shared.log(event: .adLoadFail(.admob, placement, error))
    }
    self.state = .error
    didError?()
  }
  
  func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
    guard state == .loading else {
      return
    }
    print("[MediationAd] [AdManager] [AdMob] [NativeAd] Did load! (\(String(describing: placement)))")
    if let placement {
      let time = TimeManager.shared.end(event: .adLoad(placement))
      LogEventManager.shared.log(event: .adLoadSuccess(.admob, placement, time))
    }
    self.state = .receive
    self.nativeAd = nativeAd
    didReceive?()
    
    let network = nativeAd.responseInfo.adNetworkInfoArray.first
    print("[MediationAd] [AdManager] [AdMob] [NativeAd] Adapter(\(String(describing: network)))!")
    
    nativeAd.paidEventHandler = { [weak self] adValue in
      guard let self else {
        return
      }
      print("[MediationAd] [AdManager] [AdMob] [NativeAd] Did pay revenue(\(adValue.value))!")
      if let placement = self.placement {
        LogEventManager.shared.log(event: .adPayRevenue(.admob, placement))
        if adValue.value == 0 {
          LogEventManager.shared.log(event: .adNoRevenue(.admob, placement))
        }
      }
      let adRevenueParams: [AnyHashable: Any] = [
        kAppsFlyerAdRevenueCountry: "US",
        kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
        kAppsFlyerAdRevenueAdType: "AdMob_Native"
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

extension AdMobNativeAd {
  private func load() {
    guard state == .wait else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [AdMob] [NativeAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    print("[MediationAd] [AdManager] [AdMob] [NativeAd] Start load! (\(String(describing: placement)))")
    self.state = .loading
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      var options: [GADAdLoaderOptions]? = nil
      if self.isFullScreen {
        let aspectRatioOption = GADNativeAdMediaAdLoaderOptions()
        aspectRatioOption.mediaAspectRatio = .portrait
        options = [aspectRatioOption]
      }
      if let placement {
        LogEventManager.shared.log(event: .adLoadRequest(.admob, placement))
        TimeManager.shared.start(event: .adLoad(placement))
      }
      self.adLoader = GADAdLoader(
        adUnitID: adUnitID,
        rootViewController: rootViewController,
        adTypes: [.native],
        options: options)
      self.adLoader?.delegate = self
      self.adLoader?.load(GADRequest())
    }
    
    if let timeout {
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
        guard let self else {
          return
        }
        guard state == .loading else {
          return
        }
        print("[MediationAd] [AdManager] [AdMob] [NativeAd] Load fail (\(String(describing: placement))) - time out!")
        if let placement {
          LogEventManager.shared.log(event: .adLoadTimeout(.admob, placement))
        }
        self.state = .error
        didError?()
      }
    }
  }
}
