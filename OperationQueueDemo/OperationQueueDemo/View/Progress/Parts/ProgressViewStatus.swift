//
//  ProgressViewStatus.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import UIKit

enum ProgressViewStatus {
    /// 開始可能
    case available
    /// 実行中(パーセンテージ)
    case inProgress(percent: Double)
    ///  完了
    case complete
    ///  失敗
    case failed
    /// キャンセル
    case cancelled
    /// ローディング
    case loading
}

extension ProgressViewStatus {

    public var isHiddenLayers: Bool {
        switch self {
        case .available,
             .complete,
             .failed,
             .cancelled:
            return true
        case .inProgress,
             .loading:
            return false
        }
    }

    var progressColor: CGColor {
        return UIColor.blue.cgColor
    }

    var bgColor: CGColor {
        return UIColor.gray.cgColor
    }

    var image: UIImage? {
        switch self {
        case .complete:
            return UIImage(systemName: "checkmark.seal.fill")?.withTintColor(.blue)
        case .failed:
            return UIImage(systemName: "xmark.seal.fill")?.withTintColor(.blue)
        case .cancelled:
            return UIImage(systemName: "restart.circle")?.withTintColor(.blue)
        case .available,
             .inProgress,
             .loading:
            return nil
        }
    }
}
