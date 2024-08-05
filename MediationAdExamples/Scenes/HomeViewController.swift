//
//  SecondViewController.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 25/03/2022.
//

import UIKit
import MediationAd

class HomeViewController: BaseViewController {
  @IBOutlet weak var updateConsentButton: UIButton!
  
  override func viewDidAppear(_ animated: Bool) {
    self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
  }
  
  override func binding() {
    ConsentManager.shared.$consentState
      .sink { [weak self] consentState in
        guard let self else {
          return
        }
        updateConsentButton.isHidden = consentState != .reject
      }.store(in: &subscriptions)
  }
  
  @IBAction func touchShowInterstitialAd(_ sender: Any) {
    AdManager.shared.show(type: .interstitial,
                          name: "Interstitial_1",
                          rootViewController: self,
                          didFail: nil,
                          didHide: nil)
  }
  
  @IBAction func touchShowRewardAd(_ sender: Any) {
    AdManager.shared.show(type: .rewarded,
                          name: "Rewarded",
                          rootViewController: self, didFail: {
      print("[MediationAdExamples]", "Fail")
    }, didEarnReward: {
      print("[MediationAdExamples]", "Earn Reward")
    }, didHide: {
      print("[MediationAdExamples]", "Hide")
    })
  }
  
  @IBAction func showRewardInterstitialAd(_ sender: Any) {
    AdManager.shared.show(type: .rewardedInterstitial,
                          name: "Rewarded_Interstitial",
                          rootViewController: self, didFail: {
      print("[MediationAdExamples]", "Fail")
    }, didEarnReward: {
      print("[MediationAdExamples]", "Earn Reward")
    }, didHide: {
      print("[MediationAdExamples]", "Hide")
    })
  }
  
  @IBAction func touchInterfaceBuilder(_ sender: Any) {
    self.push(to: NativeViewController(), animated: true)
  }
  
  @IBAction func touchBanner(_ sender: Any) {
    push(to: BannerViewController(), animated: true)
  }
  
  @IBAction func touchSettingPrivacy(_ sender: Any) {
    ConsentManager.shared.requestConsentUpdate { consentState in
      print("[MediationAdExamples]", consentState)
    }
  }
}
