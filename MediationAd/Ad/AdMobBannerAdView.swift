//
//  AdMobBannerView.swift
//  AdManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

open class AdMobBannerAdView: UIView {
  enum State {
    case wait
    case loading
    case receive
    case error
  }
  
  private lazy var bannerAdView: GADBannerView! = {
    let bannerView = GADBannerView()
    bannerView.translatesAutoresizingMaskIntoConstraints = false
    return bannerView
  }()
  
  public enum Anchored: String {
    case top
    case bottom
  }
  
  private weak var rootViewController: UIViewController?
  private var adUnitID: String?
  private var adName: String?
  private var anchored: Anchored?
  private var state: State = .wait
  private var didReceive: Handler?
  private var didError: Handler?
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    addComponents()
    setConstraints()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    addComponents()
    setConstraints()
  }

  required public init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public override func removeFromSuperview() {
    self.bannerAdView = nil
    super.removeFromSuperview()
  }
  
  public func load(name: String,
                   rootViewController: UIViewController,
                   didReceive: Handler?,
                   didError: Handler?
  ) {
    self.didReceive = didReceive
    self.didError = didError
    self.rootViewController = rootViewController
    
    guard adUnitID == nil else {
      return
    }
    switch AdManager.shared.status(type: .onceUsed(.banner), name: name) {
    case false:
      print("[MediationAd] [AdManager] [AdMob] [BannerAd] Ads are not allowed to show! (\(String(describing: adUnitID)))")
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
    self.adName = ad.name
    if let anchored = ad.anchored {
      self.anchored = Anchored(rawValue: anchored)
    }
    load()
  }
}

extension AdMobBannerAdView: GADBannerViewDelegate {
  public func bannerView(_ bannerView: GADBannerView,
                         didFailToReceiveAdWithError error: Error
  ) {
    print("[MediationAd] [AdManager] [AdMob] [BannerAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    LogEventManager.shared.log(event: .adLoadFail(.admob, .onceUsed(.banner), adUnitID))
    self.state = .error
    errored()
  }
  
  public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
    print("[MediationAd] [AdManager] [AdMob] [BannerAd] Did load! (\(String(describing: adUnitID)))")
    let time = TimeManager.shared.end(event: .adLoad(.admob, .onceUsed(.banner), adUnitID, adName))
    LogEventManager.shared.log(event: .adLoadSuccess(.admob, .onceUsed(.banner), adUnitID, time))
    self.state = .receive
    self.bringSubviewToFront(self.bannerAdView)
    didReceive?()
    
    let network = bannerAdView.responseInfo?.adNetworkInfoArray.first
    print("[MediationAd] [AdManager] [AdMob] [BannerAd] Adapter(\(String(describing: network)))!")
    
    bannerView.paidEventHandler = { [weak self] adValue in
      guard let self else {
        return
      }
      print("[MediationAd] [AdManager] [AdMob] [BannerAd] Did pay revenue(\(adValue.value))!")
      LogEventManager.shared.log(event: .adPayRevenue(.admob, .onceUsed(.banner), adUnitID))
      if adValue.value != 0 {
        LogEventManager.shared.log(event: .adHadRevenue(.admob, .onceUsed(.banner), adUnitID))
      }
      let adRevenueParams: [AnyHashable: Any] = [
        kAppsFlyerAdRevenueCountry: "US",
        kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
        kAppsFlyerAdRevenueAdType: "AdMob_Banner"
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

extension AdMobBannerAdView {
  private func addComponents() {
    addSubview(bannerAdView)
  }
  
  private func setConstraints() {
    let constraints = [
      bannerAdView.topAnchor.constraint(equalTo: self.topAnchor),
      bannerAdView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      bannerAdView.leftAnchor.constraint(equalTo: self.leftAnchor),
      bannerAdView.rightAnchor.constraint(equalTo: self.rightAnchor)
    ]
    NSLayoutConstraint.activate(constraints)
  }
  
  private func errored() {
    didError?()
  }
  
  private func load() {
    guard state == .wait else {
      return
    }
    
    guard let adUnitID else {
      print("[MediationAd] [AdManager] [AdMob] [BannerAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    print("[MediationAd] [AdManager] [AdMob] [BannerAd] Start load! (\(String(describing: adUnitID)))")
    self.state = .loading
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      self.bannerAdView?.adUnitID = adUnitID
      self.bannerAdView?.delegate = self
      self.bannerAdView?.rootViewController = rootViewController
      
      let request = GADRequest()
      
      if let anchored = self.anchored {
        let extras = GADExtras()
        extras.additionalParameters = ["collapsible": anchored.rawValue]
        request.register(extras)
      }
      
      LogEventManager.shared.log(event: .adLoadRequest(.admob, .onceUsed(.banner), adUnitID))
      TimeManager.shared.start(event: .adLoad(.admob, .onceUsed(.banner), adUnitID, adName))
      self.bannerAdView?.load(request)
    }
  }
}
