//
//  AdConfigProtocol.swift
//  
//
//  Created by Trịnh Xuân Minh on 15/11/2023.
//

import Foundation

protocol AdConfigProtocol: Codable {
  var placement: String { get }
  var status: Bool { get }
  var name: String { get }
  var isAuto: Bool? { get }
  var network: MonetizationNetwork { get }
  var id: String { get }
  var description: String? { get }
}
