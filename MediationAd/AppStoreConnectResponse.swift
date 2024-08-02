//
//  AppStoreConnectResponse.swift
//  
//
//  Created by Trịnh Xuân Minh on 19/06/2024.
//

import Foundation

struct AppStoreConnectResponse: Codable {
  let versions: [Version]
  
  enum CodingKeys: String, CodingKey {
    case versions = "data"
  }
}
