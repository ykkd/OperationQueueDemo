//
//  AsynchronousOperation.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import Foundation

// MARK: AsynchronousOperation
/// 非同期処理時の利用を想定したOperationのサブクラス
/// - Note: Operationに非同期タスクをそのまま渡すと、非同期タスクの完了を待たずに次のOperationに行ってしまう問題があるのですが、
/// finish()を実行するまで未完了扱いにしてくれます
///
/// - Reference:
/// [Stack Overflow](https://stackoverflow.com/questions/43561169/trying-to-understand-asynchronous-operation-subclass)
open class AsynchronousOperation: Operation {

    /// Operationの進捗を表現したenum
    @objc
    private enum OperationState: Int {
        case ready
        case executing
        case finished
    }

    /// スレッドセーフにstateにアクセス可能にする
    private let stateQueue = DispatchQueue(label: "asynchronous.operation.state", attributes: .concurrent)

    private var rawState: OperationState = .ready

    @objc private dynamic var state: OperationState {
        get { return self.stateQueue.sync { self.rawState } }
        set { self.stateQueue.sync(flags: .barrier) { self.rawState = newValue } }
    }
}

extension AsynchronousOperation {

    override open var isReady: Bool {
        return self.state == .ready && super.isReady
    }

    override public final var isExecuting: Bool {
        return self.state == .executing
    }

    override public final var isFinished: Bool {
        return self.state == .finished
    }
}

// MARK: KVO for Operation State
extension AsynchronousOperation {

    override open class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if ["isReady", "isFinished", "isExecuting"].contains(key) {
            return [#keyPath(state)]
        }
        return super.keyPathsForValuesAffectingValue(forKey: key)
    }
}

// MARK: Execution
extension AsynchronousOperation {

    override public final func start() {
        if self.isCancelled {
            self.finish()
            return
        }

        self.state = .executing
        self.main()
    }

    /// Subclasses must implement this to perform their work and they must not call `super`. The default implementation of this function throws an exception.
    override open func main() {
        fatalError("Subclasses must implement `main`.")
    }

    /// 非同期処理の完了時に実行することでOperationを完了扱いにする
    /// この関数を実行しない限り完了扱いにならないので注意
    public final func finish() {
        if !self.isFinished {
            let semaphore = DispatchSemaphore(value: 0)
            let finishBlock = { [weak self] in
                self?.completionBlock?()
                self?.completionBlock = nil
                semaphore.signal()
            }
            finishBlock()
            semaphore.wait()
            self.state = .finished
        }
    }
}
