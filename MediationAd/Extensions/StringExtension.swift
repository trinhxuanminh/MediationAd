//
//  StringExtension.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 22/08/2024.
//

import Foundation

extension String {
  func lastCharacters(_ count: Int) -> String {
    guard count > 0 else {
      return String()
    }
    guard string.count > count else {
      return self
    }
    
    let endIndex = self.index(self.endIndex, offsetBy: -count)
    return String(self[endIndex...])
  }
}
