//
//  SequentialOperationExecutor.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import Foundation

protocol SequentialOperationExecutorDelegate: NSObject {
    func startPreparation()

    func inProgress(
        numberOfFinishedOperations finishedCount: Int,
        numberOfTotalOperations totalCount: Int
    )

    func willFinish()

    func didFinish()

    func didFail(_ error: Error?)

    func willCancel()

    func didCancel()
}

final class SequentialOpearationExecutor: NSObject {

    private var progressObservation: NSKeyValueObservation?

    /// queueに追加する全Operationの数。進捗計算に利用する
    private var totalOperationCount: Int = 0

    /// 進捗が最後に外部に通知された時刻 初期値はinit時
    private var lastProgressPublishedTime: DispatchTime = .now()

    /// 進捗の外部通知バッファー
    ///
    /// - Note:
    /// アプリ側で進捗更新に関わる処理を行う際に、安全に実行できるようにバッファーを設けています
    private let progressPublishBufferTime: TimeInterval = 0.5

    private var delegate: SequentialOperationExecutorDelegate?

    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    /// 一連の処理の流れ
    private var phase: OperationPhase = .initialized

    init(_ delegate: SequentialOperationExecutorDelegate?) {
        super.init()
        self.delegate = delegate
        self.startProgressObservation()

        OSLogger.shared.log("init SequentialOperationExecutor")
    }

    deinit {
        OSLogger.shared.log("deinit SequentialOperationExecutor")
    }
}

// MARK: Control
extension SequentialOpearationExecutor {

    func start() {
        self.delegate?.startPreparation()
        self.executeOperationsInOrder()
    }

    func cancel() {
        self.delegate?.willCancel()
        self.progressObservation = nil
        self.queue.cancelAllOperations()
        self.phase = .cancel
    }
}

// MARK: Execute Operations
extension SequentialOpearationExecutor {

    private func executeOperationsInOrder() {
        DispatchQueue.global(qos: .userInitiated).async {
            // 前処理
            if !self.phase.shouldAvoidOperations {
                OSLogger.shared.log("preparation start")
                self.phase = .preparation
                let preparationOperations = self.getPreparationOperations()
                self.queue.addOperations(preparationOperations, waitUntilFinished: true)
            }
            // 本処理
            if !self.phase.shouldAvoidOperations {
                OSLogger.shared.log("in progress")
                self.phase = .inProgress
                let inProgressOperations = self.getInProgressOperations()
                self.totalOperationCount = inProgressOperations.count
                self.queue.addOperations(inProgressOperations, waitUntilFinished: true)
            }
            // 完了処理
            if !self.phase.shouldAvoidOperations {
                OSLogger.shared.log("will finish")
                self.phase = .willFinish
                let willFinishOperations = self.getWillFinishOperations()
                self.queue.addOperations(willFinishOperations, waitUntilFinished: true)
                self.delegate?.willFinish()
            }
            // キャンセルされた際の処理
            if self.phase.isCancelled {
                OSLogger.shared.log("cancelled")
                let cancelOperations = self.getCancelOperations()
                self.queue.addOperations(cancelOperations, waitUntilFinished: true)
                self.delegate?.didCancel()
            } else {
                OSLogger.shared.log("did finish")
                self.phase = .didFinish
                self.delegate?.didFinish()
            }
        }
    }
}

// MARK: Operations by Phase
extension SequentialOpearationExecutor {

    private func getPreparationOperations() -> [Operation] {
        return [DelayOperation(),DelayOperation()]
    }

    private func getInProgressOperations() -> [Operation] {
        let count = Int.random(in: 10...20)

        var operations = [DelayOperation]()
        for _ in 0...count {
            let interval = TimeInterval.random(in: 1...3)
            operations.append(DelayOperation(interval: interval))
        }
        return operations
    }

    private func getWillFinishOperations() -> [Operation] {
        let willFinishOperation = DelayOperation()
        willFinishOperation.completionBlock = {
            Thread.sleep(forTimeInterval: 2.0)
            OSLogger.shared.log("willFinish operation completed")
        }
        return [willFinishOperation]
    }

    private func getCancelOperations() -> [Operation] {
        let cancelOperation = DelayOperation()
        cancelOperation.completionBlock = {
            Thread.sleep(forTimeInterval: 2.0)
            OSLogger.shared.log("cancel operation completed")
        }
        return [cancelOperation]
    }
}

// MARK: Progress Observation
extension SequentialOpearationExecutor {

    private func startProgressObservation() {
        self.progressObservation = self.queue.observe(
            \.operationCount,
             options: [.new, .old],
             changeHandler: { [weak self] _, value in
                // pageDownload中にoperationCountが減少した場合進捗計算へ進む
                guard let self,
                      self.phase == .inProgress,
                      let latestOperationCount = value.newValue,
                      let previousOperationCount = value.oldValue,
                      latestOperationCount < previousOperationCount else {
                    return
                }

                // 総Operation数は通知されるOperatonCountの最大値
                if latestOperationCount > self.totalOperationCount {
                    self.totalOperationCount = latestOperationCount
                }
                // 完了済みOperation数は 総数 - 残数
                let numberOfFinishedOperations = self.totalOperationCount - latestOperationCount

                 self.publishProgressIfNeeded(numberOfFinishedOperations)
             }
        )
    }

    /// バッファ期間中ではない場合進捗を通知する
    private func publishProgressIfNeeded(_ finished: Int) {
        guard .now() > self.lastProgressPublishedTime + self.progressPublishBufferTime else {
            return
        }

        // ダウンロード進捗を通知する
        self.delegate?.inProgress(
            numberOfFinishedOperations: finished,
            numberOfTotalOperations: self.totalOperationCount
        )
        self.lastProgressPublishedTime = .now()
    }
}

// MARK: OpearationPhase
extension SequentialOpearationExecutor {

    enum OperationPhase {
        /// 初期状態
        case initialized
        /// 前処理実行中
        case preparation
        /// 進行中
        case inProgress
        /// 後処理
        case willFinish
        /// 一連のOperationを全て終了
        case didFinish
        /// 処理の途中でキャンセル
        case cancel
        /// 処理の失敗
        case didFail
    }
}

extension SequentialOpearationExecutor.OperationPhase {

    /// 処理がキャンセルされた場合 true
    var isCancelled: Bool {
        switch self {
        case .cancel:
            return true
        case .initialized,
             .preparation,
             .inProgress,
             .willFinish,
             .didFinish,
             .didFail:
            return false
        }
    }

    /// 処理が失敗もしくはキャンセルされた場合 true
    var shouldAvoidOperations: Bool {
        switch self {
        case .cancel,
             .didFail:
            return true
        case .initialized,
             .preparation,
             .inProgress,
             .willFinish,
             .didFinish:
            return false
        }
    }
}
