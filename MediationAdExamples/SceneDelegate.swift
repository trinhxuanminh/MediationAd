//
//  SceneDelegate.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import UIKit
import MediationAd

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    TrackingManager.shared.requestAuthorization(completed: nil)
    guard let topVC = UIApplication.topViewController() else {
      return
    }
    AdManager.shared.show(type: .appOpen,
                          name: "App_Open",
                          rootViewController: topVC,
                          didFail: nil,
                          didHide: nil)
  }
}

