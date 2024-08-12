//
//  AppManager.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseRemoteConfig
import FBAudienceNetwork

public class AppManager {
  public static let shared = AppManager()
  
  public enum State {
    case wait
    case success
    case timeout
  }
  
  enum Keys {
    static let consentKey = "CMP"
  }
  
  @Published private(set) var state: State = .wait
  private let timeout = 15.0
  private var subscriptions = Set<AnyCancellable>()
  private var didError: Handler?
  
  public func initialize(appID: String,
                         issuerID: String,
                         keyID: String,
                         privateKey: String,
                         adConfigKey: String,
                         defaultData: Data,
                         maxSdkKey: String? = nil,
                         devKey: String? = nil,
                         trackingTimeout: Double? = nil,
                         completed: @escaping RemoteHandler,
                         didError: Handler? = nil
  ) {
    guard state != .wait else {
      return
    }
    self.state = .wait
    self.didError = didError
    
    FirebaseApp.configure()
    FBAdSettings.setDataProcessingOptions([])
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutConfig)
    
    print("[MediationAd] [AppManager] Start config!")
    NetworkManager.shared.$isConnected
      .sink { [weak self] isConnected in
        guard let self else {
          return
        }
        guard isConnected else {
          return
        }
        guard state == .wait else {
          return
        }
        self.state = .success
        print("[MediationAd] [AppManager] Did setup!")
        
        RemoteManager.shared.remoteSubject
          .sink { state in
            completed(state, RemoteManager.shared.remoteConfig)
            
            switch state {
            case .success:
              let consentData = RemoteManager.shared.remoteConfig.configValue(forKey: Keys.consentKey).dataValue
              ConsentManager.shared.update(consentData: consentData)
            default:
              break
            }
          }.store(in: &subscriptions)
        
        Publishers.Zip3(ReleaseManager.shared.releaseSubject,
                        ConsentManager.shared.consentSubject,
                        RemoteManager.shared.remoteSubject)
        .sink { releaseState, consentState, remoteState in
          print("[MediationAd] [AppManager] (Release: \(releaseState)) - (Consent: \(consentState)) - (Remote: \(remoteState))")
          
          let adConfigData = RemoteManager.shared.remoteConfig.configValue(forKey: adConfigKey).dataValue
          AdManager.shared.register(isRelease: releaseState == .live || releaseState == .error,
                                    isConsent: consentState == .allow || consentState == .error,
                                    defaultData: defaultData,
                                    remoteData: adConfigData)
        }.store(in: &subscriptions)
        
        ReleaseManager.shared.initialize(appID: appID,
                                         keyID: keyID,
                                         issuerID: issuerID,
                                         privateKey: privateKey)
        ConsentManager.shared.initialize(maxSdkKey: maxSdkKey)
        RemoteManager.shared.initialize()
        
        if let devKey {
          TrackingManager.shared.initialize(devKey: devKey,
                                            appID: appID,
                                            timeout: trackingTimeout)
        }
      }.store(in: &subscriptions)
  }
}

extension AppManager {
  private func timeoutConfig() {
    guard state == .wait else {
      return
    }
    self.state = .timeout
    didError?()
  }
}
