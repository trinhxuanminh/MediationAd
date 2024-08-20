//
//  TimeManager.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 20/08/2024.
//

import Foundation
import AVFoundation

class TimeManager {
  static let shared = TimeManager()
  
  private var startTimes: [String: CFTimeInterval] = [:]
  
  func start(event: Event) {
    let start = CACurrentMediaTime()
    startTimes[event.key] = start
  }
  
  func end(event: Event) -> Double {
    let end = CACurrentMediaTime()
    guard let start = startTimes.removeValue(forKey: event.key) else {
      return 0
    }
    return Double(end - start).rounded(decimalPlaces: 1)
  }
  
  enum Event {
    case appManagerConfig
    case remoteManagerLoad
    case releaseManagerCheck
    case consentManagerCheck
    case adLoad(MonetizationNetwork, AdManager.AdType, String?, String?)
    
    var key: String {
      switch self {
      case .adLoad(let monetizationNetwork, let adType, let adUnitID, let adName):
        return "\(self)_\(monetizationNetwork)_\(adType)_\(adUnitID ?? String())_\(adName ?? String())"
      default:
        return "\(self)"
      }
    }
  }
}
