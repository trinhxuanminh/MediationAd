//
//  UIViewExtension.swift
//  MediationAd
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit

extension UIView {
  func loadNibNamed() {
    Bundle.main.loadNibNamed(String(describing: Self.className), owner: self)
  }
}
