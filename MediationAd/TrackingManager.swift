//
//  TrackingManager.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import Foundation
import AppTrackingTransparency
import AppsFlyerLib
import FirebaseAnalytics
import AdSupport
import PurchaseConnector
import StoreKit
import AppsFlyerAdRevenue

public class TrackingManager: NSObject {
  public static let shared = TrackingManager()
  
  public func debug(enable: Bool) {
    AppsFlyerLib.shared().isDebug = enable
  }
  
  public func sandbox(enable: Bool) {
    PurchaseConnector.shared().isSandbox = enable
  }
  
  public func status() -> Bool {
    guard
      #available(iOS 14, *),
      ATTrackingManager.trackingAuthorizationStatus == .notDetermined
    else {
      return false
    }
    return true
  }
  
  public func requestAuthorization(completed: Handler?) {
    guard
      #available(iOS 14, *),
      status()
    else {
      completed?()
      return
    }
    ATTrackingManager.requestTrackingAuthorization { status in
      switch status {
      case .authorized:
        print("[AppManager] [TrackingManager] Enable!")
        print("[AppManager] [TrackingManager] \(ASIdentifierManager.shared().advertisingIdentifier)")
        Analytics.setAnalyticsCollectionEnabled(true)
        LogEventManager.shared.log(event: .agreeTracking)
      default:
        print("[AppManager] [TrackingManager] Disable!")
        Analytics.setAnalyticsCollectionEnabled(false)
        LogEventManager.shared.log(event: .noTracking)
      }
      completed?()
    }
  }
}

extension TrackingManager {
  func initialize(devKey: String, appID: String, timeout: Double?) {
    AppsFlyerLib.shared().appsFlyerDevKey = devKey
    AppsFlyerLib.shared().appleAppID = appID
    AppsFlyerLib.shared().delegate = self
    
    PurchaseConnector.shared().purchaseRevenueDelegate = self
    PurchaseConnector.shared().purchaseRevenueDataSource = self
    PurchaseConnector.shared().autoLogPurchaseRevenue = [.autoRenewableSubscriptions, .inAppPurchases]
    
    AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: timeout ?? 45.0)
    
    NotificationCenter
      .default
      .addObserver(self,
                   selector: #selector(sendLaunch),
                   name: UIApplication.didBecomeActiveNotification,
                   object: nil)
    
    AppsFlyerAdRevenue.start()
    
    if #available(iOS 14, *),
       ATTrackingManager.trackingAuthorizationStatus == .authorized {
      Analytics.setAnalyticsCollectionEnabled(true)
    }
  }
}

extension TrackingManager {
  @objc private func sendLaunch() {
    AppsFlyerLib.shared().start(completionHandler: { (dictionary, error) in
      guard error == nil else {
        print("[AppManager] [TrackingManager] \(String(describing: error))!")
        LogEventManager.shared.log(event: .noConnectAppsFlyer)
        return
      }
      print("[AppManager] [TrackingManager] \(String(describing: dictionary))")
      LogEventManager.shared.log(event: .connectedAppsFlyer)
    })
    PurchaseConnector.shared().startObservingTransactions()
  }
}

extension TrackingManager: PurchaseRevenueDataSource, PurchaseRevenueDelegate {
  public func didReceivePurchaseRevenueValidationInfo(_ validationInfo: [AnyHashable : Any]?,
                                                      error: Error?
  ) {
    print("[AppManager] [TrackingManager] PurchaseRevenueDelegate: \(String(describing: validationInfo))")
    print("[AppManager] [TrackingManager] PurchaseRevenueDelegate: \(String(describing: error))")
  }
  
  public func purchaseRevenueAdditionalParameters(for products: Set<SKProduct>,
                                                  transactions: Set<SKPaymentTransaction>?
  ) -> [AnyHashable : Any]? {
    return [
      "additionalParameters": [
        "param1": "value1",
        "param2": "value2"
      ]
    ]
  }
}

extension TrackingManager: AppsFlyerLibDelegate {
  public func onConversionDataSuccess(_ installData: [AnyHashable: Any]) {
    guard let status = installData["af_status"] as? String else {
      return
    }
    if status == "Non-organic" {
      // Business logic for Non-organic install scenario is invoked
      if let sourceID = installData["media_source"],
         let campaign = installData["campaign"] {
        print("[AppManager] [TrackingManager] This is a Non-organic install. Media source: \(sourceID)  Campaign: \(campaign)")
      }
    } else {
      // Business logic for organic install scenario is invoked
    }
  }
  
  public func onConversionDataFail(_ error: Error) {
    // Logic for when conversion data resolution fails
    print("[AppManager] [TrackingManager] Error: \(error)")
  }
}
