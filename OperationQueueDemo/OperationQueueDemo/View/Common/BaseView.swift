//
//  BaseView.swift
//  OperationQueueDemo
//
//  Created by ykkd on 2022/12/21.
//

import UIKit

class BaseView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    func commonInit() {
        self.loadXib()
    }
}
