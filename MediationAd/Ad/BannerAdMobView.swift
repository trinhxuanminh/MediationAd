//
//  BannerAdMobView.swift
//  AdMobManager
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import GoogleMobileAds
import AppsFlyerAdRevenue

/// This class returns a UIView displaying BannerAd.
/// ```
/// import AdMobManager
/// ```
/// Ad display is automatic.
/// - Warning: Ad will not be displayed without adding ID.
open class BannerAdMobView: UIView {
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
  
  func addComponents() {
    addSubview(bannerAdView)
  }
  
  func setConstraints() {
    let constraints = [
      bannerAdView.topAnchor.constraint(equalTo: self.topAnchor),
      bannerAdView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      bannerAdView.leftAnchor.constraint(equalTo: self.leftAnchor),
      bannerAdView.rightAnchor.constraint(equalTo: self.rightAnchor)
    ]
    NSLayoutConstraint.activate(constraints)
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
    switch AdMobManager.shared.status(type: .onceUsed(.banner), name: name) {
    case false:
      print("[AdMobManager] [BannerAd] Ads are not allowed to show! (\(String(describing: adUnitID)))")
      errored()
      return
    case true:
      break
    default:
      errored()
      return
    }
    guard let ad = AdMobManager.shared.getAd(type: .onceUsed(.banner), name: name) as? Banner else {
      return
    }
    guard ad.status else {
      return
    }
    self.adUnitID = ad.id
    if let anchored = ad.anchored {
      self.anchored = Anchored(rawValue: anchored)
    }
    load()
  }
}

extension BannerAdMobView: GADBannerViewDelegate {
  public func bannerView(_ bannerView: GADBannerView,
                         didFailToReceiveAdWithError error: Error
  ) {
    print("[AdMobManager] [BannerAd] Load fail (\(String(describing: adUnitID))) - \(String(describing: error))!")
    self.state = .error
    errored()
  }
  
  public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
    print("[AdMobManager] [BannerAd] Did load! (\(String(describing: adUnitID)))")
    self.state = .receive
    self.bringSubviewToFront(self.bannerAdView)
    didReceive?()
    
    bannerView.paidEventHandler = { [weak self] adValue in
      guard let self else {
        return
      }
      let adRevenueParams: [AnyHashable: Any] = [
        kAppsFlyerAdRevenueCountry: "US",
        kAppsFlyerAdRevenueAdUnit: adUnitID as Any,
        kAppsFlyerAdRevenueAdType: "Banner"
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

extension BannerAdMobView {
  private func errored() {
    didError?()
  }
  
  private func load() {
    guard state == .wait else {
      return
    }
    
    guard let adUnitID = adUnitID else {
      print("[AdMobManager] [BannerAd] Failed to load - not initialized yet! Please install ID.")
      return
    }
    
    print("[AdMobManager] [BannerAd] Start load! (\(String(describing: adUnitID)))")
    self.state = .loading
    DispatchQueue.main.async { [weak self] in
      guard let self = self else {
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
      
      self.bannerAdView?.load(request)
    }
  }
}
