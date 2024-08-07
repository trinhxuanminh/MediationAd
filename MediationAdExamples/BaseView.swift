//
//  BaseView.swift
//  MediationAdExamples
//
//  Created by Trịnh Xuân Minh on 07/08/2024.
//

import UIKit
import Combine

class BaseView: UIView, ViewProtocol {
  var subscriptions = Set<AnyCancellable>()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addComponents()
    setConstraints()
    setProperties()
    binding()
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      setColor()
    }
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    addComponents()
    setConstraints()
    setProperties()
    binding()
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        return
      }
      setColor()
    }
  }
  
  deinit {
    removeSubs()
  }
  
  func addComponents() {}
  
  func setConstraints() {}
  
  func setProperties() {}
  
  func setColor() {}
  
  func binding() {}
  
  func removeSubs() {
    subscriptions.forEach { $0.cancel() }
    subscriptions.removeAll()
  }
}
