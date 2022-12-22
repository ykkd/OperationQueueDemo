//
//  DelayOpearation.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import Foundation

/// 他のOperationを依存させることで待機処理を実現する非同期Operation
open class DelayOperation: AsynchronousOperation {

    private let delay: TimeInterval
    private let qos: DispatchQoS.QoSClass

    public init(interval: TimeInterval = 1.0, qos: DispatchQoS.QoSClass = .userInitiated) {
        self.delay = interval
        self.qos = qos
        super.init()
    }

    override open func main() {
        guard self.delay > 0 else {
            self.finish()
            return
        }
        OSLogger.shared.log("DelayOperation start")

        let when = DispatchTime.now() + self.delay
        DispatchQueue(label: "delay operation \(UUID())", qos: .userInitiated).asyncAfter(deadline: when) { [weak self] in
            OSLogger.shared.log("DelayOperation finish")
            self?.finish()
        }
    }
}
