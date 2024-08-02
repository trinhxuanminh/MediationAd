////
////  ReleaseManager.swift
////  MediationAd
////
////  Created by Trịnh Xuân Minh on 02/08/2024.
////
//
//import Foundation
//import Combine
////import SwiftJWT
//
//public class ReleaseManager {
//  public static let shared = ReleaseManager()
//  
//  enum Keys {
//    static let cache = "RELEASE_CACHE"
//    static let readyForSale = "READY_FOR_SALE"
//  }
//  
//  public enum State {
//    case unknow
//    case waitReview
//    case live
//    case error
//  }
//  
//  @Published public private(set) var releaseState: State = .unknow
//  let releaseSubject = PassthroughSubject<State, Never>()
//  private var nowVersion: Double = 0.0
//  private var releaseVersion: Double = 0.0
//  private let timeout = 15.0
//  private var appID: String!
//  private var keyID: String!
//  private var issuerID: String!
//  private var privateKey: String!
//}
//
//extension ReleaseManager {
//  func initialize(appID: String,
//                  keyID: String,
//                  issuerID: String,
//                  privateKey: String
//  ) {
//    self.appID = appID
//    self.keyID = keyID
//    self.issuerID = issuerID
//    self.privateKey = privateKey
//    
//    fetch()
//    check()
//  }
//}
//
//extension ReleaseManager {
//  private func check() {
//    guard
//      let nowVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
//      let nowVersion = Double(nowVersionString)
//    else {
//      // Không lấy được version hiện tại.
//      change(state: .error)
//      return
//    }
//    self.nowVersion = nowVersion
//    
//    if nowVersion <= releaseVersion {
//      // Version hiện tại đã release, đã được cache.
//      change(state: .live)
//    } else {
//      DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
//        guard let self else {
//          return
//        }
//        // Quá thời gian timeout chưa trả về, mặc định trạng thái bật.
//        change(state: .error)
//      }
//      Task {
//        // Check version đang release trên Itunes.
//        let itunesReleaseState = await itunesReleaseState()
//        switch itunesReleaseState {
//        case .live, .error:
//          change(state: itunesReleaseState)
//        case .unknow:
//          // Check version đang release trên AppStoreConnect khi dữ liệu itunes chưa kịp cập nhật.
//          let appStoreConnectRelease = await appStoreConnectReleaseState()
//          change(state: appStoreConnectRelease)
//        case .waitReview:
//          break
//        }
//      }
//    }
//  }
//  
//  private func itunesReleaseState() async -> State {
//    do {
//      guard let bundleId = Bundle.main.bundleIdentifier else {
//        // Không lấy được bundleId.
//        return .error
//      }
//      
//      let regionCodeClean: String
//      if let regionCode = Locale.current.regionCode,
//         let cleanPath = regionCode.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
//        regionCodeClean = cleanPath
//      } else {
//        regionCodeClean = "us"
//      }
//      
//      let endPoint = EndPoint.itunesVersion(regionCode: regionCodeClean, bundleId: bundleId)
//      let itunesResponse: ItunesResponse = try await APIService().request(from: endPoint)
//      guard let result = itunesResponse.results.first else {
//        // Hiện tại chưa có version nào release.
//        return .unknow
//      }
//      let releaseVersionString = result.version
//      guard let releaseVersion = Double(releaseVersionString) else {
//        // Không convert được sang dạng số thập phân.
//        return .error
//      }
//
//      if nowVersion <= releaseVersion {
//        // Version hiện tại đã release. Cache version.
//        update(releaseVersion)
//        return .live
//      } else {
//        // Version hiện tại chưa release.
//        return .unknow
//      }
//    } catch let error {
//      // Lỗi không load được version release, mặc định trạng thái bật.
//      print("[AppManager] [ReleaseManager] error: \(error)")
//      return .error
//    }
//  }
//  
//  private func appStoreConnectReleaseState() async -> State {
////    do {
////      guard let privateData = privateKey.data(using: .utf8) else {
////        return .error
////      }
////      let jwtSigner = JWTSigner.es256(privateKey: privateData)
////      
////      let limitTime = 300.0
////      let claims = TokenClaims(iss: issuerID,
////                               exp: Date(timeIntervalSinceNow: limitTime),
////                               aud: "appstoreconnect-v1")
////      let header = Header(kid: keyID)
////      var jwt = JWT(header: header, claims: claims)
////      
////      let token = try jwt.sign(using: jwtSigner)
////      
////      let endPoint = EndPoint.appStoreConnectVersion(appID: appID, token: token)
////      let appStoreConnectResponse: AppStoreConnectResponse = try await APIService().request(from: endPoint)
////      guard let version = appStoreConnectResponse.versions.first(where: { $0.attributes.state == Keys.readyForSale }) else {
////        // Hiện tại chưa có version nào release.
////        return .waitReview
////      }
////      let releaseVersionString = version.attributes.version
////      guard let releaseVersion = Double(releaseVersionString) else {
////        // Không convert được sang dạng số thập phân.
////        return .error
////      }
////
////      if nowVersion <= releaseVersion {
////        // Version hiện tại đã release. Cache version.
////        update(releaseVersion)
////        return .live
////      } else {
////        // Version hiện tại chưa release.
////        return .waitReview
////      }
////    } catch let error {
////      // Lỗi không load được version release, mặc định trạng thái bật.
////      print("[AppManager] [ReleaseManager] error: \(error)")
//      return .error
////    }
//  }
//  
//  private func change(state: State) {
//    guard releaseState == .unknow else {
//      return
//    }
//    self.releaseState = state
//    releaseSubject.send(state)
//    
//    print("[AppManager] [ReleaseManager] state: \(state)")
//  }
//  
//  private func fetch() {
//    self.releaseVersion = UserDefaults.standard.double(forKey: Keys.cache)
//  }
//  
//  private func update(_ releaseVersion: Double) {
//    UserDefaults.standard.set(releaseVersion, forKey: Keys.cache)
//    fetch()
//  }
//}
