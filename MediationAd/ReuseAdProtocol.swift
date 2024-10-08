//
//  AdProtocol.swift
//  
//
//  Created by Trịnh Xuân Minh on 23/06/2022.
//

import UIKit

@objc protocol ReuseAdProtocol {
  func config(didFail: Handler?, didSuccess: Handler?)
  func config(id: String)
  func isPresent() -> Bool
  @objc optional func isExist() -> Bool
  func show(rootViewController: UIViewController,
            didFail: Handler?,
            willPresent: Handler?,
            didEarnReward: Handler?,
            didHide: Handler?)
}

extension ReuseAdProtocol {
  func config(timeout: Double) {}
}
