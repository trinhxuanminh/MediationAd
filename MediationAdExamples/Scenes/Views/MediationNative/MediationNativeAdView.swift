//
//  MediationNativeAdView.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit
import SnapKit
import MediationAd
import NVActivityIndicatorView

class MediationNativeAdView: BaseView {
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

extension MediationNativeAdView {
  func load(placement: String, didError: Handler? = nil) {
    switch AdManager.shared.network(type: .onceUsed(.native), placement: placement) {
    case .admob:
      let nativeAdView = CustomAdMobNativeAdView()
      containerView.addSubview(nativeAdView)
      nativeAdView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      nativeAdView.load(placement: placement, didReceive: { [weak self] in
        guard let self else {
          return
        }
        loadingView.stopAnimating()
      }, didError: didError)
    case .max:
      let nativeAdView = CustomMaxNativeAdView()
      containerView.addSubview(nativeAdView)
      nativeAdView.snp.makeConstraints { make in
        make.edges.equalToSuperview()
      }
      nativeAdView.load(placement: placement, didReceive: { [weak self] in
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
