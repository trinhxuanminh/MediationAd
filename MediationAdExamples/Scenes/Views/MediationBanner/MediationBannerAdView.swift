//
//  MediationBannerAdView.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit
import SnapKit
import MediationAd
import NVActivityIndicatorView

class MediationBannerAdView: BaseView {
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var containerView: UIView!
  
  private lazy var loadingView: NVActivityIndicatorView = {
    let loadingView = NVActivityIndicatorView(frame: .zero)
    loadingView.type = .ballPulse
    loadingView.padding = 25.0
    loadingView.color = UIColor(rgb: 0xFFFFFF)
    return loadingView
  }()
  
  override func addComponents() {
    loadNibNamed()
    addSubview(contentView)
    addSubview(loadingView)
  }
  
  override func setConstraints() {
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    loadingView.snp.makeConstraints { make in
      make.width.height.equalTo(20.0)
      make.center.equalToSuperview()
    }
  }
  
  override func setProperties() {
    loadingView.startAnimating()
  }
}

extension MediationBannerAdView {
  func load(name: String, didError: Handler? = nil) {
    guard let topVC = UIApplication.topViewController() else {
      return
    }
    switch AdManager.shared.network(type: .onceUsed(.banner), name: name) {
    case .admob:
      let bannerAdView = AdMobBannerAdView()
      containerView.addSubview(bannerAdView)
      bannerAdView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      bannerAdView.load(name: name, rootViewController: topVC, didReceive: { [weak self] in
        guard let self else {
          return
        }
        loadingView.stopAnimating()
      }, didError: didError)
    case .max:
      let bannerAdView = MaxBannerAdView()
      containerView.addSubview(bannerAdView)
      bannerAdView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      bannerAdView.load(name: name, rootViewController: topVC, didReceive: { [weak self] in
        guard let self else {
          return
        }
        loadingView.stopAnimating()
      }, didError: didError)
    default:
      didError?()
    }
  }
}
