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
  
  private var subscriptions = Set<AnyCancellable>()
  private var didSetup = false
  
  public func initialize(appID: String,
                         devKey: String,
                         trackingTimeout: Double,
                         issuerID: String,
                         keyID: String,
                         privateKey: String,
                         completed: @escaping RemoteHandler
  ) {
    FirebaseApp.configure()
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
        
        RemoteManager.shared.remoteSubject
          .sink { state in
            completed(state, RemoteManager.shared.remoteConfig)
          }.store(in: &subscriptions)
        
        Publishers.Zip3(ReleaseManager.shared.releaseSubject,
                        ConsentManager.shared.consentSubject,
                        RemoteManager.shared.remoteSubject)
        .sink { releaseState, consentState, remoteState in
          print("[AppManager] (Release: \(releaseState)) - (Consent: \(consentState)) - (Remote: \(remoteState))")
        }.store(in: &subscriptions)
        
        TrackingManager.shared.initialize(devKey: devKey,
                                          appID: appID,
                                          timeout: trackingTimeout)
        ReleaseManager.shared.initialize(appID: appID,
                                         keyID: keyID,
                                         issuerID: issuerID,
                                         privateKey: privateKey)
        ConsentManager.shared.initialize()
        RemoteManager.shared.initialize()
      }.store(in: &subscriptions)
  }
}
