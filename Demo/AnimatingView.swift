//
//  AnimatingView.swift
//  RHAnimator
//
//  Created by Rolf Hendriks on 8/20/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

import UIKit

class AnimatingView: UIView {

    override var accessibilityFrame: CGRect{
        get{ return super.accessibilityFrame.insetBy(dx: -20, dy: -20)}
        set{}
    }
}
