//
//  AppDelegate.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import UIKit
import MediationAd

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let appID = "6599836028"
    let devKey = ""
    let issuerID = "90feb1ef-b49e-466f-bdf0-6c854e6042e2"
    let keyID = "6U7525RU8W"
    let privateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQgPIQil7g03C5nf0Cr
    UO78c9YuqPRO11jV7/UN3frXe6ugCgYIKoZIzj0DAQehRANCAAQYWA+t6rSkTz+9
    WxVKpmxLLqEc2O9sPCA7Lhq0/nI1mHSHPi9Lge5ZBEzqisiEgVvZ5OuX7JlfUC4r
    Gu7+MCYD
    -----END PRIVATE KEY-----
    """
    
    AppManager.shared.initialize(appID: appID,
                                 devKey: devKey,
                                 trackingTimeout: 45.0,
                                 issuerID: issuerID,
                                 keyID: keyID,
                                 privateKey: privateKey
    ) { remoteState, remoteConfig in
      print(remoteState)
    }
    return true
  }
}
