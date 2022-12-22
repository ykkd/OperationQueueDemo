//
//  OSLogger.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import Foundation
import OSLog

final class OSLogger {

    static let shared = OSLogger()

    private let logger = Logger()

    private init() {}

    func log(
        _ message: String,
        category: Category = .general
    ) {
        self.logger.debug("[\(category.rawValue)] \(message, privacy: .public)")
    }
}

// MARK: OSLogger.Category
extension OSLogger {

    enum Category: String {
        case general
        case animation
    }
}
