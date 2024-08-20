//
//  RemoteManager.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import Foundation
import Combine
import FirebaseRemoteConfig

public class RemoteManager {
  public static let shared = RemoteManager()
  
  public enum State: String {
    case wait
    case success
    case error
    case timeout
  }
  
  @Published public private(set) var remoteState: State = .wait
  let remoteSubject = PassthroughSubject<State, Never>()
  let remoteConfig = RemoteConfig.remoteConfig()
  private let remoteTimeout = 10.0
}

extension RemoteManager {
  func initialize() {
    fetchRemote()
  }
}

extension RemoteManager {
  private func fetchRemote() {
    guard remoteState == .wait else {
      return
    }
    print("[MediationAd] [RemoteManager] Start load!")
    LogEventManager.shared.log(event: .remoteManagerStartLoad)
    TimeManager.shared.start(event: .remoteManagerLoad)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + remoteTimeout, execute: timeoutRemote)
    
    remoteConfig.fetch(withExpirationDuration: 0) { [weak self] _, error in
      guard let self else {
        return
      }
      guard error == nil else {
        errorRemote()
        return
      }
      
      guard remoteState == .wait else {
        return
      }
      self.remoteConfig.activate()
      
      print("[MediationAd] [RemoteManager] Success!")
      change(state: .success)
    }
  }
  
  private func errorRemote() {
    guard remoteState == .wait else {
      return
    }
    print("[MediationAd] [RemoteManager] First load error!")
    change(state: .error)
  }
  
  private func timeoutRemote() {
    guard remoteState == .wait else {
      return
    }
    print("[MediationAd] [RemoteManager] First load timeout!")
    LogEventManager.shared.log(event: .remoteManagerTimeout)
    
    change(state: .timeout)
  }
  
  private func change(state: State) {
    guard remoteState == .wait else {
      return
    }
    self.remoteState = state
    remoteSubject.send(state)
    let time = TimeManager.shared.end(event: .remoteManagerLoad)
    LogEventManager.shared.log(event: .remoteManagerChange(state, state == .success ? time : nil))
  }
}
