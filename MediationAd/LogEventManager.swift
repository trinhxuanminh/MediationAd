//
//  LogEventManager.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 02/08/2024.
//

import Foundation
import FirebaseAnalytics

class LogEventManager {
  static let shared = LogEventManager()
  
  class func adType(_ adType: AdManager.AdType) -> String {
    switch adType {
    case .onceUsed(let type):
      return type.rawValue
    case .reuse(let type):
      return type.rawValue
    }
  }
  
  func log(event: Event) {
    Analytics.logEvent(event.name, parameters: event.parameters)
    if AppManager.shared.debugLogEvent {
      print("[MediationAd] [LogEventManager]", "[\(isValid(event.name))]", event.name, event.parameters ?? String())
    }
  }
  
  private func isValid(_ input: String) -> Bool {
    guard input.count <= 40 else {
      return false
    }
    let pattern = "^[a-zA-Z0-9_]*$"
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(location: 0, length: input.utf16.count)
    return regex.firstMatch(in: input, options: [], range: range) != nil
  }
  
  enum Event {
    static let unknow = "Unknow"
    static let maxCharacter = 6
    
    case appManagerStartSession
    case appManagerStartConfig
    case appManagerSuccess(Double)
    case appManagerTimeout
    
    case remoteManagerStartLoad
    case remoteManagerSuccess(Double)
    case remoteManagerError(Double)
    case remoteManagerTimeout
    
    case releaseManagerStartCheck
    case releaseManagerWaitReview(Double)
    case releaseManagerLive(Double)
    case releaseManagerError(Double)
    case releaseManagerTimeout
    
    case consentManagerUseCache
    case consentManagerInvalidFormat
    case consentManagerStartCheck
    case consentManagerNotRequest
    case consentManagerRequest
    case consentManagerTimeout
    case consentManagerInfoError
    case consentManagerFormError
    case consentManagerAgree(Double)
    case consentManagerReject(Double)
    case consentManagerError(Double)
    case consentManagerAutoAgree
    case consentManagerAutoAgreeGDPR
    case consentManagerUpdateRequest
    case consentManagerUpdateAgree
    case consentManagerUpdateReject
    case consentManagerUpdateError
    
    case trackingManagerConnected
    case trackingManagerNoConnect
    case trackingManagerAgree
    case trackingManagerReject
    
    case adManagerStartRegister
    case adManagerRemoteInvaidFormat
    case adManagerCacheInvaidFormat
    case adManagerLocalInvaidFormat
    case adManagerSuccess
    case adManagerPremium
    case adManagerReject
    case adManagerError
    
    case adLoadRequest(MonetizationNetwork, AdManager.AdType, String?)
    case adLoadFail(MonetizationNetwork, AdManager.AdType, String?)
    case adLoadRetryFail(MonetizationNetwork, AdManager.AdType, String?)
    case adLoadTimeout(MonetizationNetwork, AdManager.AdType, String?)
    case adLoadSuccess(MonetizationNetwork, AdManager.AdType, String?, Double)
    case adShowRequest(MonetizationNetwork, AdManager.AdType, String?)
    case adShowFail(MonetizationNetwork, AdManager.AdType, String?)
    case adShowSuccess(MonetizationNetwork, AdManager.AdType, String?)
    case adShowHide(MonetizationNetwork, AdManager.AdType, String?)
    case adClick(MonetizationNetwork, AdManager.AdType, String?)
    case adEarnReward(MonetizationNetwork, AdManager.AdType, String?)
    case adPayRevenue(MonetizationNetwork, AdManager.AdType, String?)
    case adHadRevenue(MonetizationNetwork, AdManager.AdType, String?)
    
    var name: String {
      switch self {
      case .appManagerStartSession:
        return "AppManager_Start_Session"
      case .appManagerStartConfig:
        return "AppManager_Start_Config"
      case .appManagerSuccess:
        return "AppManager_Success"
      case .appManagerTimeout:
        return "AppManager_Timeout"
        
      case .remoteManagerStartLoad:
        return "RemoteManager_Start_Load"
      case .remoteManagerTimeout:
        return "RemoteManager_Timeout"
      case .remoteManagerSuccess:
        return "RemoteManager_Success"
      case .remoteManagerError:
        return "RemoteManager_Error"
        
      case .releaseManagerStartCheck:
        return "ReleaseManager_Start_Check"
      case .releaseManagerWaitReview:
        return "ReleaseManager_WaitReview"
      case .releaseManagerLive:
        return "ReleaseManager_Live"
      case .releaseManagerError:
        return "ReleaseManager_Error"
      case .releaseManagerTimeout:
        return "ReleaseManager_Timeout"
        
      case .consentManagerUseCache:
        return "ConsentManager_Use_Cache"
      case .consentManagerInvalidFormat:
        return "ConsentManager_Invalid_Format"
      case .consentManagerStartCheck:
        return "ConsentManager_Start_Check"
      case .consentManagerNotRequest:
        return "ConsentManager_Not_Request"
      case .consentManagerRequest:
        return "ConsentManager_Request"
      case .consentManagerTimeout:
        return "ConsentManager_Timeout"
      case .consentManagerInfoError:
        return "ConsentManager_Info_Error"
      case .consentManagerFormError:
        return "ConsentManager_Form_Error"
      case .consentManagerAgree:
        return "ConsentManager_Agree"
      case .consentManagerReject:
        return "ConsentManager_Reject"
      case .consentManagerError:
        return "ConsentManager_Error"
      case .consentManagerAutoAgree:
        return "ConsentManager_Auto_Agree"
      case .consentManagerAutoAgreeGDPR:
        return "ConsentManager_Auto_Agree_GDPR"
      case .consentManagerUpdateRequest:
        return "ConsentManager_Update_Request"
      case .consentManagerUpdateAgree:
        return "ConsentManager_Update_Agree"
      case .consentManagerUpdateReject:
        return "ConsentManager_Update_Reject"
      case .consentManagerUpdateError:
        return "ConsentManager_Update_Error"
        
      case .trackingManagerConnected:
        return "TrackingManager_Connected"
      case .trackingManagerNoConnect:
        return "TrackingManager_No_Connect"
      case .trackingManagerAgree:
        return "TrackingManager_Agree"
      case .trackingManagerReject:
        return "TrackingManager_Reject"
        
      case .adManagerStartRegister:
        return "AdManager_Start_Register"
      case .adManagerRemoteInvaidFormat:
        return "AdManager_Remote_Invaid_Format"
      case .adManagerCacheInvaidFormat:
        return "AdManager_Cache_Invaid_Format"
      case .adManagerLocalInvaidFormat:
        return "AdManager_Local_Invaid_Format"
      case .adManagerSuccess:
        return "AdManager_Success"
      case .adManagerPremium:
        return "AdManager_Premium"
      case .adManagerReject:
        return "AdManager_Reject"
      case .adManagerError:
        return "AdManager_Error"
        
      case .adLoadRequest(let network, let adType, let adUnitID):
        return "Ad_Load_Request_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? LogEventManager.Event.unknow)"
      case .adLoadFail(let network, let adType, let adUnitID):
        return "Ad_Load_Fail_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adLoadRetryFail(let network, let adType, let adUnitID):
        return "Ad_Load_Retry_Fail_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adLoadTimeout(let network, let adType, let adUnitID):
        return "Ad_Load_Timeout_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adLoadSuccess(let network, let adType, let adUnitID, _):
        return "Ad_Load_Success_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adShowRequest(let network, let adType, let adUnitID):
        return "Ad_Show_Request_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adShowFail(let network, let adType, let adUnitID):
        return "Ad_Show_Fail_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adShowSuccess(let network, let adType, let adUnitID):
        return "Ad_Show_Success_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adShowHide(let network, let adType, let adUnitID):
        return "Ad_Show_Hide_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adClick(let network, let adType, let adUnitID):
        return "Ad_Click_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adEarnReward(let network, let adType, let adUnitID):
        return "Ad_Earn_Reward_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adPayRevenue(let network, let adType, let adUnitID):
        return "Ad_Pay_Revenue_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      case .adHadRevenue(let network, let adType, let adUnitID):
        return "Ad_Had_Revenue_\(network.rawValue.capitalized)_\(LogEventManager.adType(adType).capitalized)_\(adUnitID?.lastCharacters(LogEventManager.Event.maxCharacter) ?? "Unknow")"
      }
    }
    
    var parameters: [String: Any]? {
      switch self {
      case .appManagerSuccess(let time):
        return ["time": time]
        
      case .remoteManagerSuccess(let time):
        return ["time": time]
      case .remoteManagerError(let time):
        return ["time": time]
        
      case .releaseManagerWaitReview(let time):
        return ["time": time]
      case .releaseManagerLive(let time):
        return ["time": time]
      case .releaseManagerError(let time):
        return ["time": time]
        
      case .consentManagerAgree(let time):
        return ["time": time]
      case .consentManagerReject(let time):
        return ["time": time]
      case .consentManagerError(let time):
        return ["time": time]
        
      case .adLoadSuccess(_, _, _, let time):
        return ["time": time]
      default:
        return nil
      }
    }
  }

}
