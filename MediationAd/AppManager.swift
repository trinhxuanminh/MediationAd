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

public class AppManager {
  public static let shared = AppManager()
  
  enum Keys {
    static let consentKey = "CMP"
  }
  
  private var subscriptions = Set<AnyCancellable>()
  private var didSetup = false
  
  public func initialize(appID: String,
                         issuerID: String,
                         keyID: String,
                         privateKey: String,
                         adConfigKey: String,
                         defaultData: Data,
                         maxSdkKey: String? = nil,
                         devKey: String? = nil,
                         trackingTimeout: Double? = nil,
                         completed: @escaping RemoteHandler
  ) {
    FirebaseApp.configure()
    print("[MediationAd] [AppManager] Start config!")
    NetworkManager.shared.$isConnected
      .sink { [weak self] isConnected in
        guard let self else {
          return
        }
        guard isConnected else {
          return
        }
        guard !didSetup else {
          return
        }
        self.didSetup = true
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
