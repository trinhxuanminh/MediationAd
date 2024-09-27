//
//  Splash.swift
//  
//
//  Created by Trịnh Xuân Minh on 06/09/2023.
//

import Foundation

struct Splash: AdConfigProtocol {
  let placement: String
  let status: Bool
  let name: String
  let network: MonetizationNetwork
  let id: String
  let isAuto: Bool?
  let description: String?
  let timeout: Double
}
