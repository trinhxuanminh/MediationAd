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
  private var isFullScreen = false
  private var timeout: Double?
  private var state: State = .wait
  private var didReceive: Handler?
  private var didError: Handler?
  
  func config(ad: Native, rootViewController: UIViewController?) {
    self.rootViewController = rootViewController
    guard ad.status else {
      return
    }
    guard adUnitID == nil else {
      return
    }
    self.adUnitID = ad.id
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
    print("[MediationAd] [AdManager] [NativeAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    self.state = .error
    didError?()
  }
  
  func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
    guard state == .loading else {
      return
    }
    print("[MediationAd] [AdManager] [NativeAd] Did load! (\(String(describing: adUnitID)))")
    self.state = .receive
    self.nativeAd = nativeAd
    didReceive?()
    
    nativeAd.paidEventHandler = { [weak self] adValue in
      guard let self else {
        return
      }
      let adRevenueParams: [AnyHashable: Any] = [
        kAppsFlyerAdRevenueCountry: "US",
        kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
        kAppsFlyerAdRevenueAdType: "Native"
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
    
    guard let adUnitID = adUnitID else {
      print("[MediationAd] [AdManager] [NativeAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    print("[MediationAd] [AdManager] [NativeAd] Start load! (\(String(describing: adUnitID)))")
    self.state = .loading
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
        return
      }
      var options: [GADAdLoaderOptions]? = nil
      if self.isFullScreen {
        let aspectRatioOption = GADNativeAdMediaAdLoaderOptions()
        aspectRatioOption.mediaAspectRatio = .portrait
        options = [aspectRatioOption]
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
        guard let self = self else {
          return
        }
        guard state == .loading else {
          return
        }
        print("[MediationAd] [AdManager] [NativeAd] Load fail (\(String(describing: adUnitID))) - time out!")
        self.state = .error
        didError?()
      }
    }
  }
}
