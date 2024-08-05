//
//  SplashViewController.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import MediationAd
import Combine

class SplashViewController: BaseViewController {
  override func binding() {
    AdManager.shared.$registerState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] state in
        guard let self else {
          return
        }
        switch state {
        case .success, .error:
          AdManager.shared.load(type: .splash, name: "Splash_1", success: showAds, fail: toHome)
          AdManager.shared.load(type: .interstitial, name: "Interstitial_1")
          AdManager.shared.load(type: .interstitial, name: "Interstitial_2")
          AdManager.shared.load(type: .appOpen, name: "App_Open")
          AdManager.shared.load(type: .rewarded, name: "Rewarded")
          AdManager.shared.load(type: .rewardedInterstitial, name: "Rewarded_Interstitial")
          AdManager.shared.preloadNative(name: "Native")
        case .reject, .premium:
          self.toHome()
        case .wait:
          break
        }
      }.store(in: &subscriptions)
  }
  
  func showAds() {
    AdManager.shared.show(type: .splash,
                          name: "Splash_1",
                          rootViewController: self,
                          didFail: toHome,
                          didHide: toHome)
  }
  
  func toHome() {
    self.push(to: HomeViewController(), animated: false)
  }
}
