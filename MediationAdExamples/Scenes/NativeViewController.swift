//
//  NativeViewController.swift
//  AdmobLibraryDemo
//
//  Created by Trịnh Xuân Minh on 05/12/2022.
//

import UIKit

class NativeViewController: BaseViewController {
  @IBOutlet weak var nativeAdView: MediationNativeAdView!
  
  override func setProperties() {
    nativeAdView.isHidden = false
    nativeAdView.load(name: "Native", didError: { [weak self] in
      guard let self else {
        return
      }
      nativeAdView.isHidden = true
    })
  }
}
