//
//  NSObject+.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import Foundation

// クラス名を取得する。
// Objective-CのNSStringFromClassに相当する
extension NSObject {

    static var className: String {
        return String(describing: self)
    }

    var className: String {
        return type(of: self).className
    }
}
