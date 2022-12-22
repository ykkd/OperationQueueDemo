//
//  StrokeAnimation.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import UIKit

// MARK: StrokeAnimation
final class StrokeAnimation: CABasicAnimation {

    init(
        type: StrokeType,
        beginTime: Double = 0.0,
        fromValue: CGFloat,
        toValue: CGFloat,
        duration: Double
    ) {
        super.init()
        self.keyPath = type.keyPath
        self.beginTime = beginTime
        self.fromValue = fromValue
        self.toValue = toValue
        self.duration = duration
        self.timingFunction = .init(name: .easeInEaseOut)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: StrokeAnimation.StrokeType
extension StrokeAnimation {

    enum StrokeType {
        case start
        case end

        var keyPath: String {
            switch self {
            case .start:
                return "strokeStart"
            case .end:
                return "strokeEnd"
            }
        }
    }
}
