//
//  MaxBannerAdView.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 06/08/2024.
//

import UIKit
import SnapKit
import AppLovinSDK
import AppsFlyerAdRevenue

open class MaxBannerAdView: UIView {
  enum State {
    case wait
    case loading
    case receive
    case error
  }
  
  private weak var rootViewController: UIViewController?
  private var bannerAdView: MAAdView?
  private var adUnitID: String?
  private var state: State = .wait
  private var didReceive: Handler?
  private var didError: Handler?
  
  public override func removeFromSuperview() {
    self.bannerAdView = nil
    super.removeFromSuperview()
  }
  
  public func load(name: String,
                   rootViewController: UIViewController,
                   didReceive: Handler?,
                   didError: Handler?
  ) {
    self.rootViewController = rootViewController
    self.didReceive = didReceive
    self.didError = didError
    
    guard adUnitID == nil else {
      return
    }
    switch AdManager.shared.status(type: .onceUsed(.banner), name: name) {
    case false:
      print("[MediationAd] [AdManager] [Max] [BannerAd] Ads are not allowed to show! (\(String(describing: adUnitID)))")
      errored()
      return
    case true:
      break
    default:
      errored()
      return
    }
    guard let ad = AdManager.shared.getAd(type: .onceUsed(.banner), name: name) as? Banner else {
      return
    }
    guard ad.status else {
      return
    }
    self.adUnitID = ad.id
    load()
  }
}

extension MaxBannerAdView: MAAdViewAdDelegate, MAAdRevenueDelegate {
  public func didExpand(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did expand! (\(String(describing: adUnitID)))")
  }
  
  public func didCollapse(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did collapse! (\(String(describing: adUnitID)))")
  }
  
  public func didLoad(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did load! (\(String(describing: adUnitID)))")
    self.state = .receive
    didReceive?()
  }
  
  public func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    self.state = .error
    errored()
  }
  
  public func didDisplay(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did display! (\(String(describing: adUnitID)))")
  }
  
  public func didHide(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did hide! (\(String(describing: adUnitID)))")
  }
  
  public func didClick(_ ad: MAAd) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did click! (\(String(describing: adUnitID)))")
  }
  
  public func didFail(toDisplay ad: MAAd, withError error: MAError) {
    print("[MediationAd] [AdManager] [Max] [BannerAd] Did fail to show content! (\(String(describing: adUnitID)))")
  }
  
  public func didPayRevenue(for ad: MAAd) {
    let adRevenueParams: [AnyHashable: Any] = [
      kAppsFlyerAdRevenueCountry: "US",
      kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
      kAppsFlyerAdRevenueAdType: "Max_Banner"
    ]
    
    AppsFlyerAdRevenue.shared().logAdRevenue(
      monetizationNetwork: "applovinmax",
      mediationNetwork: MediationNetworkType.applovinMax,
      eventRevenue: ad.revenue as NSNumber,
      revenueCurrency: "USD",
      additionalParameters: adRevenueParams)
  }
}

extension MaxBannerAdView {
  func addComponents() {
    guard
      let adUnitID,
      bannerAdView == nil
    else {
      return
    }
    let bannerAdView = MAAdView(adUnitIdentifier: adUnitID)
    self.bannerAdView = bannerAdView
    bannerAdView.frame.size = frame.size
    addSubview(bannerAdView)
  }
  
  func setConstraints() {
    bannerAdView?.snp.makeConstraints({ make in
      make.edges.equalToSuperview()
    })
  }
  
  private func errored() {
    didError?()
  }
  
  private func load() {
    guard state == .wait else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [Max] [BannerAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    print("[MediationAd] [AdManager] [Max] [BannerAd] Start load! (\(String(describing: adUnitID)))")
    self.state = .loading
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      addComponents()
      setConstraints()
      bannerAdView?.delegate = self
      bannerAdView?.revenueDelegate = self
      bannerAdView?.stopAutoRefresh()
      bannerAdView?.loadAd()
    }
  }
}
