//
//  extensionUtil.swift
//  VideoCapture
//
//  Created by 李威 on 2022/8/3.
//

import UIKit

//斜体
private var key:Void?
extension UILabel {
  var italic: Bool {
    get {
       return objc_getAssociatedObject(self, &key) as? Bool ?? false
    }
    set {
      objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      if newValue {
        self.transform = CGAffineTransform(a: 1, b: 0, c: CGFloat(tanf(Float(-15*(Double.pi)/180))), d: 1, tx: 0, ty: 0)
      }
    }
  }
}
