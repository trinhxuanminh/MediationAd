//
//  OnceUsedAdProtocol.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 05/08/2024.
//

import UIKit

protocol OnceUsedAdProtocol {
  func config(ad: Native, rootViewController: UIViewController?)
  func bind(didReceive: Handler?, didError: Handler?)
}
