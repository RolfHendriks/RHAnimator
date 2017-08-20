//
//  CurvePickerView.swift
//  RHAnimator
//
//  Created by Rolf Hendriks on 8/19/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

import UIKit

class CurveContainerView: UIControl {
    @IBOutlet var curveButton : UIButton! = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    // MARK: voice over accessibility
    private func commonInit(){
        self.isAccessibilityElement = true
        self.accessibilityLabel = "Animation Curve"
        self.accessibilityTraits = UIAccessibilityTraitButton
    }
    
    override var accessibilityValue: String?{
        get { return self.curveButton.accessibilityLabel }
        set(value) { self.curveButton.accessibilityLabel = value }
    }
    
    override func accessibilityActivate() -> Bool {
        return self.curveButton.accessibilityActivate()
    }
}
