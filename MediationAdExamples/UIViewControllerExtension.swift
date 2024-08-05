//
//  UIViewControllerExtension.swift
//  Wallpaper_Gacha_Life
//
//  Created by Trịnh Xuân Minh on 05/04/2021.
//

import Foundation
import UIKit

extension UIViewController {
    @objc func pop(animated: Bool) {
        self.navigationController?.popViewController(animated: animated)
    }
    
    @objc func push(to viewController: UIViewController, animated: Bool) {
        self.navigationController?.pushViewController(viewController, animated: animated)
    }
    
    class func loadFromNib() -> Self {
        func loadFromNib<T: UIViewController>(_ type: T.Type) -> T {
            return T.init(nibName: String(describing: T.self), bundle: nil)
        }
        return loadFromNib(self)
    }
    
    @objc func present(to viewController: UIViewController, animated: Bool) {
        self.present(viewController, animated: animated, completion: nil)
    }
}

extension UIView {
  class func initFromNib() -> Self {
    return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?[0] as! Self
  }
}
