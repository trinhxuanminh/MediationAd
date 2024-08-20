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
      print("[MediationAd] [LogEventManager]", event.name, event.parameters ?? String())
    }
  }
  
  enum Event {
    case appManagerStartSession
    case appManagerStartConfig
    case appManagerSuccess(Double)
    case appManagerTimeout
    
    case remoteManagerStartLoad
    case remoteManagerChange(RemoteManager.State, Double?)
    case remoteManagerTimeout
    
    case releaseManagerStartCheck
    case releaseManagerChange(ReleaseManager.State, Double?)
    case releaseManagerTimeout
    
    case consentManagerUseCache
    case consentManagerInvalidFormat
    case consentManagerStartCheck
    case consentManagerNotRequest
    case consentManagerRequest
    case consentManagerTimeout
    case consentManagerInfoError
    case consentManagerFormError
    case consentManagerAgree
    case consentManagerReject
    case consentManagerAutoAgree
    case consentManagerAutoAgreeGDPR
    case consentManagerChange(ConsentManager.State, Double?)
    case consentManagerUpdateRequest
    case consentManagerUpdateFormError
    case consentManagerUpdateChange(ConsentManager.State)
    
    case trackingManagerConnected
    case trackingManagerNoConnect
    case trackingManagerAgree
    case trackingManagerReject
    
    case adManagerChange(AdManager.State)
    case adManagerStartRegister
    case adManagerInvaidFormat
    
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
      case .remoteManagerChange:
        return "RemoteManager_Change"
      case .releaseManagerStartCheck:
        return "ReleaseManager_Start_Check"
      case .releaseManagerChange:
        return "ReleaseManager_Change"
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
      case .consentManagerAutoAgree:
        return "ConsentManager_Auto_Agree"
      case .consentManagerAutoAgreeGDPR:
        return "ConsentManager_Auto_Agree_GDPR"
      case .consentManagerChange:
        return "ConsentManager_Change"
      case .consentManagerUpdateRequest:
        return "ConsentManager_Update_Request"
      case .consentManagerUpdateFormError:
        return "ConsentManager_Update_Form_Error"
      case .consentManagerUpdateChange:
        return "ConsentManager_Update_Change"
      case .trackingManagerConnected:
        return "TrackingManager_Connected"
      case .trackingManagerNoConnect:
        return "TrackingManager_No_Connect"
      case .trackingManagerAgree:
        return "TrackingManager_Agree"
      case .trackingManagerReject:
        return "TrackingManager_Reject"
      case .adManagerChange:
        return "AdManager_Change"
      case .adManagerStartRegister:
        return "AdManager_Start_Register"
      case .adManagerInvaidFormat:
        return "AdManager_Invaid_Format"
      case .adLoadRequest(let monetizationNetwork, _, _):
        return "Ad_Load_Request_\(monetizationNetwork.rawValue.capitalized)"
      case .adLoadFail(let monetizationNetwork, _, _):
        return "Ad_Load_Fail_\(monetizationNetwork.rawValue.capitalized)"
      case .adLoadRetryFail(let monetizationNetwork, _, _):
        return "Ad_Load_Retry_Fail_\(monetizationNetwork.rawValue.capitalized)"
      case .adLoadTimeout(let monetizationNetwork, _, _):
        return "Ad_Load_Timeout_\(monetizationNetwork.rawValue.capitalized)"
      case .adLoadSuccess(let monetizationNetwork, _, _, _):
        return "Ad_Load_Success_\(monetizationNetwork.rawValue.capitalized)"
      case .adShowRequest(let monetizationNetwork, _, _):
        return "Ad_Show_Request_\(monetizationNetwork.rawValue.capitalized)"
      case .adShowFail(let monetizationNetwork, _, _):
        return "Ad_Show_Fail_\(monetizationNetwork.rawValue.capitalized)"
      case .adShowSuccess(let monetizationNetwork, _, _):
        return "Ad_Show_Success_\(monetizationNetwork.rawValue.capitalized)"
      case .adShowHide(let monetizationNetwork, _, _):
        return "Ad_Show_Hide_\(monetizationNetwork.rawValue.capitalized)"
      case .adClick(let monetizationNetwork, _, _):
        return "Ad_Click_\(monetizationNetwork.rawValue.capitalized)"
      case .adEarnReward(let monetizationNetwork, _, _):
        return "Ad_Earn_Reward_\(monetizationNetwork.rawValue.capitalized)"
      case .adPayRevenue(let monetizationNetwork, _, _):
        return "Ad_Pay_Revenue_\(monetizationNetwork.rawValue.capitalized)"
      case .adHadRevenue(let monetizationNetwork, _, _):
        return "Ad_Had_Revenue_\(monetizationNetwork.rawValue.capitalized)"
      }
    }
    
    var parameters: [String: Any]? {
      switch self {
      case .appManagerSuccess(let time):
        return ["time": time]
      case .releaseManagerChange(let state, let time):
        var param = ["state": state.rawValue]
        if let time {
          param["time"] = String(time)
        }
        return param
      case .remoteManagerChange(let state, let time):
        var param = ["state": state.rawValue]
        if let time {
          param["time"] = String(time)
        }
        return param
      case .consentManagerChange(let state, let time):
        var param = ["state": state.rawValue]
        if let time {
          param["time"] = String(time)
        }
        return param
      case .consentManagerUpdateChange(let state):
        return ["state": state.rawValue]
      case .adManagerChange(let state):
        return ["state": state.rawValue]
      case .adLoadRequest(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adLoadFail(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adLoadRetryFail(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adLoadTimeout(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adLoadSuccess(_, let adType, let adUnitID, let time):
        return [
          LogEventManager.adType(adType): adUnitID ?? String(),
          "time": time
        ]
      case .adShowRequest(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adShowFail(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adShowSuccess(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adShowHide(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adClick(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adEarnReward(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adPayRevenue(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      case .adHadRevenue(_, let adType, let adUnitID):
        return [LogEventManager.adType(adType): adUnitID ?? String()]
      default:
        return nil
      }
    }
  }

}
