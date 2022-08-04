//
//  MirrorUtil.swift
//  VideoCapture
//
//  Created by 李威 on 2022/8/3.
//

import Foundation

class Person {
  var name = ""
  var nickName: String?
  var age = 0
  
  init(name:String="Tom", nickName:String? = "cat", age:Int = 18) {
    self.name = name
    self.nickName = nickName
    self.age = age
  }
  
  func fetchMirror(_ obj: Any){
    let mirror = Mirror(reflecting: obj)
    print("类型：\(mirror.subjectType)")
    print("个数：\(mirror.children.count)")
    for (key, value) in mirror.children {
      print("属性：\(String(describing: key)),值：\(value)")
    }
  }
  
  func fetchPropertyList(_ obj: Any) {
    var count: UInt32 = 0
    guard let propertyList = class_copyPropertyList(objc_getClass(obj as! UnsafePointer<CChar>) as! AnyClass, &count) else {
      return
    }
    
    for i in 0..<Int(count) {
      let property = propertyList[i]
      let cpropertyName = property_getName(property)
      let propertyName = String(utf8String: cpropertyName)
      
      guard let cpropertyAttr = property_getAttributes(property) else {
        return
      }
      let propertyAttr = String(utf8String: cpropertyAttr)
      
      print("propertyName: \(String(describing: propertyName) ?? " "), propertyAttr:\(propertyAttr)")
    }
    
    free(propertyList)
  }
}
