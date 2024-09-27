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
    super.viewDidAppear(animated)
    removeInteractivePopGestureRecognizer()
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
                          placement: AppText.AdName.interstitial,
                          rootViewController: self,
                          didFail: nil,
                          didHide: nil)
  }
  
  @IBAction func touchShowRewardAd(_ sender: Any) {
    AdManager.shared.show(type: .rewarded,
                          placement: AppText.AdName.rewarded,
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
                          placement: AppText.AdName.rewardedInterstitial,
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
  
  @IBAction func showDebug(_ sender: Any) {
    AppManager.shared.activeDebug(.ad(.admob))
  }
  
  @IBAction func touchSettingPrivacy(_ sender: Any) {
    ConsentManager.shared.requestConsentUpdate { consentState in
      print("[MediationAdExamples]", consentState)
      switch consentState {
      case .allow, .error:
        AdManager.shared.upgradeConsent()
      default:
        break
      }
    }
  }
}
