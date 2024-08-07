//
//  UIApplicationExtension.swift
//  Wallpaper_Gacha_Life
//
//  Created by Trịnh Xuân Minh on 05/04/2021.
//

import Foundation
import UIKit

extension UIApplication {
  class func topViewController(viewController: UIViewController? = UIApplication.shared.windows.first?.rootViewController) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(viewController: navigationController.visibleViewController)
    }
    if let tabBarController = viewController as? UINavigationController {
      return topViewController(viewController: tabBarController)
    }
    if let presented = viewController?.presentedViewController {
      return topViewController(viewController: presented)
    }
    return viewController
  }
}
