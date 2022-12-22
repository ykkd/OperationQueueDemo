//
//  ViewController.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var progressView: CircleProgressView!

    @IBOutlet private weak var button: UIButton!

    private var SequentialOperationExecutor: SequentialOpearationExecutor?
}

// MARK: IBAction
extension ViewController {

    @IBAction private func didTapButton(_ sender: Any) {
        if SequentialOperationExecutor != nil {
            self.cancel()
        } else {
            self.start()
        }
    }
}

// MARK: Control SequentialOperationExecutor
extension ViewController {

    func start() {
        self.SequentialOperationExecutor = SequentialOpearationExecutor(self)
        self.SequentialOperationExecutor?.start()
    }

    func cancel() {
        self.SequentialOperationExecutor?.cancel()
        self.SequentialOperationExecutor = nil
    }
}

// MARK: SequentialOperationExecutorDelegate
extension ViewController: SequentialOperationExecutorDelegate {

    func startPreparation() {
        DispatchQueue.main.async {
            self.button.setTitle("Cancel", for: .normal)
            self.progressView.setup(.loading)
        }
    }

    func inProgress(numberOfFinishedOperations finishedCount: Int, numberOfTotalOperations totalCount: Int) {
        DispatchQueue.main.async {
            let progress = Double(finishedCount) / Double(totalCount)
            OSLogger.shared.log("inProgress \(progress)")
            self.progressView.setup(.inProgress(percent: progress))
        }
    }

    func willFinish() {
        DispatchQueue.main.async {
            self.progressView.setup(.loading)
        }
    }

    func didFinish() {
        self.SequentialOperationExecutor = nil
        DispatchQueue.main.async {
            self.button.setTitle("Start", for: .normal)
            self.progressView.setup(.complete)
        }
    }

    func didFail(_ error: Error?) {
        DispatchQueue.main.async {
            self.progressView.setup(.failed)
        }
    }

    func willCancel() {
        DispatchQueue.main.async {
            self.button.setTitle("Wait..", for: .normal)
            self.button.isUserInteractionEnabled = false
            self.progressView.setup(.loading)
        }
    }

    func didCancel() {
        self.SequentialOperationExecutor = nil
        DispatchQueue.main.async {
            self.button.setTitle("Start", for: .normal)
            self.button.isUserInteractionEnabled = true
            self.progressView.setup(.cancelled)
        }
    }
}
