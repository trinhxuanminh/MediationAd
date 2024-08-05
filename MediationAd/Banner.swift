//
//  Banner.swift
//  
//
//  Created by Trịnh Xuân Minh on 23/08/2023.
//

import Foundation

struct Banner: AdConfigProtocol {
  let name: String
  let status: Bool
  let network: MonetizationNetwork
  let id: String
  let isAuto: Bool?
  let description: String?
  let anchored: String?
}
