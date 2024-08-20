//
//  BannerVC.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 06/06/2023.
//

import UIKit
import MediationAd
import SnapKit
import NVActivityIndicatorView

class BannerViewController: BaseViewController {
  @IBOutlet weak var bannerAdView: MediationBannerAdView!
  
  override func setProperties() {
    bannerAdView.isHidden = false
    bannerAdView.load(name: AppText.AdName.banner, didError: { [weak self] in
      guard let self else {
        return
      }
      bannerAdView.isHidden = true
    })
  }
}
