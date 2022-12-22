//
//  CircleProgressView.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import UIKit

// MARK: CircleProgressView
final class CircleProgressView: BaseView {

    @IBOutlet private weak var imageView: UIImageView!

    private let keyForStrokeAnimationGroup = "strokeAnimationGroup"

    /// 進捗ゲージの背景用layer
    private var bgLayer = CAShapeLayer()
    /// 進捗ゲージ用layer
    private var progressLayer = CAShapeLayer()

    override func commonInit() {
        super.commonInit()
        self.createProgressLayers()
    }

    func setup(_ status: ProgressViewStatus) {
        self.removeLoadingAnimation()
        self.setupAppearance(status)
        self.setupProgress(status)
    }
}

// MARK: Setup
extension CircleProgressView {

    private func setupAppearance(_ status: ProgressViewStatus) {
        self.bgLayer.isHidden = status.isHiddenLayers
        self.progressLayer.isHidden = status.isHiddenLayers
        self.imageView.image = status.image
        self.progressLayer.strokeColor = status.progressColor
        self.bgLayer.strokeColor = status.bgColor
    }

    private func setupProgress(_ status: ProgressViewStatus) {
        switch status {
        case let .inProgress(progress):
            self.update(to: progress)
        case .loading:
            self.startLoadingAnimation()
            self.update(to: 0)
        case .available,
             .complete,
             .failed,
             .cancelled:
            self.update(to: 0)
        }
    }

    private func createProgressLayers() {
        // 円の始点座標
        let startPoint = CGFloat(-Double.pi / 2)
        // 円の終点座標
        let endPoint = CGFloat(3 * Double.pi / 2)

        let circularPath = UIBezierPath(
            arcCenter: CGPoint(x: self.frame.width * 0.5, y: self.frame.height * 0.5),
            radius: self.frame.size.width / 2.0,
            startAngle: startPoint,
            endAngle: endPoint,
            clockwise: true
        )

        // 背景layerの設定
        self.bgLayer.path = circularPath.cgPath
        self.bgLayer.fillColor = UIColor.clear.cgColor
        self.bgLayer.lineCap = .square
        self.bgLayer.lineWidth = self.frame.size.width * 0.1
        self.bgLayer.strokeEnd = 1.0
        self.bgLayer.isHidden = true

        // 進捗layerの設定
        self.progressLayer.path = circularPath.cgPath
        self.progressLayer.fillColor = UIColor.clear.cgColor
        self.progressLayer.lineCap = .square
        self.progressLayer.lineWidth = self.frame.size.width * 0.1
        self.progressLayer.strokeEnd = 0
        self.progressLayer.isHidden = true

        // layerを追加
        self.layer.addSublayer(self.bgLayer)
        self.layer.addSublayer(self.progressLayer)
        self.layer.masksToBounds = false
    }

    private func update(to progress: Double) {
        self.progressLayer.strokeEnd = progress
    }
}

// MARK: Stroke Animation
extension CircleProgressView {

    private func startLoadingAnimation() {
        let startAnimation = StrokeAnimation(
            type: .start,
            beginTime: 0.20,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 0.25
        )

        let endAnimation = StrokeAnimation(
            type: .end,
            beginTime: 0.10,
            fromValue: 0.0,
            toValue: 1.0,
            duration: 0.35
        )

        let strokeAnimationGroup = CAAnimationGroup()
        strokeAnimationGroup.duration = 1.5
        strokeAnimationGroup.repeatDuration = .infinity
        strokeAnimationGroup.animations = [startAnimation, endAnimation]
        self.progressLayer.add(strokeAnimationGroup, forKey: self.keyForStrokeAnimationGroup)
    }

    private func removeLoadingAnimation() {
        self.progressLayer.removeAnimation(forKey: self.keyForStrokeAnimationGroup)
    }
}
