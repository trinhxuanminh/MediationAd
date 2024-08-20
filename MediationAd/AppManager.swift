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
    case unknow
    case loading
    case success
    case timeout
  }
  
  enum Keys {
    static let consentKey = "CMP"
  }
  
  @Published private(set) var state: State = .unknow
  private let timeout = 15.0
  private var subscriptions = Set<AnyCancellable>()
  private var didError: Handler?
  private var didConfigure = false
  private(set) var debugLogEvent = false
  
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
    guard state != .loading else {
      return
    }
    self.state = .loading
    self.didError = didError
    
    if !didConfigure {
      print("[MediationAd] [AppManager] Start session!")
      self.didConfigure = true
      FirebaseApp.configure()
      FBAdSettings.setDataProcessingOptions([])
      LogEventManager.shared.log(event: .appManagerStartSession)
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutConfig)
    
    print("[MediationAd] [AppManager] Start config!")
    LogEventManager.shared.log(event: .appManagerStartConfig)
    NetworkManager.shared.isConnected
      .sink { [weak self] isConnected in
        guard let self else {
          return
        }
        guard isConnected else {
          return
        }
        guard state == .loading else {
          return
        }
        self.state = .success
        print("[MediationAd] [AppManager] Did setup!")
        LogEventManager.shared.log(event: .appManagerSuccess)
        
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
  
  public func activeDebugEvent() {
    self.debugLogEvent = true
  }
}

extension AppManager {
  private func timeoutConfig() {
    guard state == .loading else {
      return
    }
    self.state = .timeout
    print("[MediationAd] [AppManager] timeout!")
    LogEventManager.shared.log(event: .appManagerTimeout)
    didError?()
  }
}
