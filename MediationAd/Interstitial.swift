//
//  Interstitial.swift
//  
//
//  Created by Trịnh Xuân Minh on 23/08/2023.
//

import Foundation

struct Interstitial: AdConfigProtocol {
  let placement: String
  let status: Bool
  let name: String
  let network: MonetizationNetwork
  let id: String
  let isAuto: Bool?
  let description: String?
  let start: Int?
  let frequency: Int?
}
