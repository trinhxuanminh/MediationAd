//
//  ConsentManager.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import UIKit
import UserMessagingPlatform
import GoogleMobileAds
import Combine

public class ConsentManager {
  public static let shared = ConsentManager()
  
  enum Keys {
    static let cache = "CONSENT_CACHE"
  }
  
  public enum State {
    case unknow
    case allow
    case reject
    case error
  }
  
  @Published public private(set) var consentState: State = .unknow
  let consentSubject = PassthroughSubject<State, Never>()
  private var didRequestConsent = false
  private let timeout = 15.0
  private var isDebug = false
  private var testDeviceIdentifiers = [String]()
  private var consentConfig: ConsentConfig?
  
  public func requestConsentUpdate(completed: @escaping ConsentHandler) {
    guard let viewController = UIApplication.topStackViewController() else {
      completed(.error)
      return
    }
    
    UMPConsentForm.presentPrivacyOptionsForm(from: viewController) { [weak self] formError in
      guard let self else {
        return
      }
      if let formError {
        print("[MediationAd] [ConsentManager] Form error - \(formError.localizedDescription)!")
        completed(.error)
        return
      }
      guard consentState != .allow else {
        completed(.allow)
        return
      }
      let canShowAds = canShowAds()
      if canShowAds {
        GADMobileAds.sharedInstance().start()
      }
      let state: State = canShowAds ? .allow : .reject
      self.consentState = state
      completed(state)
    }
  }
  
  public func activeDebug(testDeviceIdentifiers: [String], reset: Bool) {
    self.isDebug = true
    self.testDeviceIdentifiers = testDeviceIdentifiers
    if reset {
      UMPConsentInformation.sharedInstance.reset()
    }
  }
}

extension ConsentManager {
  func initialize() {
    fetch()
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
      guard let self else {
        return
      }
      // Quá thời gian timeout chưa trả về.
      change(state: .error)
    }
  }
  
  func update(consentData: Data) {
    decoding(data: consentData)
  }
}

extension ConsentManager {
  private func updateCache() {
    guard let consentConfig else {
      return
    }
    guard let data = try? JSONEncoder().encode(consentConfig) else {
      return
    }
    UserDefaults.standard.set(data, forKey: Keys.cache)
  }
  
  private func decoding(data: Data) {
    guard let consentConfig = try? JSONDecoder().decode(ConsentConfig.self, from: data) else {
      print("[MediationAd] [ConsentManager] Invalid (ConsentConfig) format!")
      return
    }
    self.consentConfig = consentConfig
    updateCache()
    check()
  }
  
  private func fetch() {
    guard let cacheData = UserDefaults.standard.data(forKey: Keys.cache) else {
      return
    }
    decoding(data: cacheData)
  }
  
  private func check() {
    guard !didRequestConsent else {
      return
    }
    self.didRequestConsent = true
    
    print("[MediationAd] [ConsentManager] Check consent!")
    LogEventManager.shared.log(event: .cmpCheckConsent)
    
    let parameters = UMPRequestParameters()
    parameters.tagForUnderAgeOfConsent = false
    
    if isDebug {
      let debugSettings = UMPDebugSettings()
      debugSettings.testDeviceIdentifiers = testDeviceIdentifiers
      debugSettings.geography = .EEA
      parameters.debugSettings = debugSettings
    } else {
      guard let consentConfig, consentConfig.status else {
        print("[MediationAd] [ConsentManager] Not request consent!")
        LogEventManager.shared.log(event: .cmpNotRequestConsent)
        change(state: .allow)
        return
      }
    }
    
    print("[MediationAd] [ConsentManager] Request consent!")
    LogEventManager.shared.log(event: .cmpRequestConsent)
    UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] requestConsentError in
      guard let self else {
        return
      }
      if let requestConsentError {
        print("[MediationAd] [ConsentManager] Request consent error - \(requestConsentError.localizedDescription)!")
        LogEventManager.shared.log(event: .cmpConsentInformationError)
        change(state: .error)
        return
      }
      
      guard let viewController = UIApplication.topStackViewController() else {
        change(state: .error)
        return
      }
      
      UMPConsentForm.loadAndPresentIfRequired(from: viewController) { [weak self] loadAndPresentError in
        guard let self else {
          return
        }
        if let loadAndPresentError {
          print("[MediationAd] [ConsentManager] Load and present error - \(loadAndPresentError.localizedDescription)!")
          LogEventManager.shared.log(event: .cmpConsentFormError)
          change(state: .error)
          return
        }
        
        guard isGDPR() else {
          print("[MediationAd] [ConsentManager] Auto agree consent GDPR!")
          LogEventManager.shared.log(event: .cmpAutoAgreeConsentGDPR)
          change(state: .allow)
          return
        }
        
        let canShowAds = canShowAds()
        if canShowAds {
          print("[MediationAd] [ConsentManager] Agree consent!")
          LogEventManager.shared.log(event: .cmpAgreeConsent)
        } else {
          print("[MediationAd] [ConsentManager] Reject consent!")
          LogEventManager.shared.log(event: .cmpRejectConsent)
        }
        change(state: canShowAds ? .allow : .reject)
      }
    }
    
    if canShowAds() {
      print("[MediationAd] [ConsentManager] Auto agree consent!")
      LogEventManager.shared.log(event: .cmpAutoAgreeConsent)
      change(state: .allow)
    }
  }
  
  private func change(state: State) {
    guard
      consentState == .unknow,
      state != .unknow
    else {
      return
    }
    switch state {
    case .allow, .error:
      GADMobileAds.sharedInstance().start()
    default:
      break
    }
    self.consentState = state
    consentSubject.send(state)
  }
  
  private func isGDPR() -> Bool {
    let settings = UserDefaults.standard
    let gdpr = settings.integer(forKey: "IABTCF_gdprApplies")
    return gdpr == 1
  }
  
  private func canShowAds() -> Bool {
    let userDefaults = UserDefaults.standard
    
    let purposeConsent = userDefaults.string(forKey: "IABTCF_PurposeConsents") ?? ""
    let vendorConsent = userDefaults.string(forKey: "IABTCF_VendorConsents") ?? ""
    let vendorLI = userDefaults.string(forKey: "IABTCF_VendorLegitimateInterests") ?? ""
    let purposeLI = userDefaults.string(forKey: "IABTCF_PurposeLegitimateInterests") ?? ""
    
    let googleId = 755
    let hasGoogleVendorConsent = hasAttribute(input: vendorConsent, index: googleId)
    let hasGoogleVendorLI = hasAttribute(input: vendorLI, index: googleId)
    
    return hasConsentFor([1], purposeConsent, hasGoogleVendorConsent)
    && hasConsentOrLegitimateInterestFor([2,7,9,10],
                                         purposeConsent,
                                         purposeLI,
                                         hasGoogleVendorConsent,
                                         hasGoogleVendorLI)
  }
  
  private func hasAttribute(input: String, index: Int) -> Bool {
    return input.count >= index && String(Array(input)[index - 1]) == "1"
  }
  
  private func hasConsentFor(_ purposes: [Int], _ purposeConsent: String, _ hasVendorConsent: Bool) -> Bool {
    return purposes.allSatisfy { i in hasAttribute(input: purposeConsent, index: i) } && hasVendorConsent
  }
  
  private func hasConsentOrLegitimateInterestFor(_ purposes: [Int],
                                                 _ purposeConsent: String,
                                                 _ purposeLI: String,
                                                 _ hasVendorConsent: Bool,
                                                 _ hasVendorLI: Bool
  ) -> Bool {
    return purposes.allSatisfy { i in
      (hasAttribute(input: purposeLI, index: i) && hasVendorLI) ||
      (hasAttribute(input: purposeConsent, index: i) && hasVendorConsent)
    }
  }
}
