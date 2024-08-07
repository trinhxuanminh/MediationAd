//
//  NSObjectExtension.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import Foundation

extension NSObject {
  public class var className: String {
    return String(describing: self)
  }
  
  public var className: String {
    return String(describing: self)
  }
}
