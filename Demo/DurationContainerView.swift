//
//  DurationPickerView.swift
//  RHAnimator
//
//  Created by Rolf Hendriks on 8/19/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

import UIKit

class DurationView: UIControl {
    @IBOutlet var durationSlider : UISlider!
    @IBOutlet var durationLabel : UILabel!

    func set (possibleDurations : [TimeInterval], duration : TimeInterval){
        assert(possibleDurations.contains(duration))
        self.possibleDurations = possibleDurations
        self.duration = duration
        self.refreshUI()
    }
    var value : TimeInterval { return duration }
    
    // MARK: PRIVATE
    private var possibleDurations : [TimeInterval] = []
    private var duration : TimeInterval = 0
    
    private var durationIndex : Int?{
        get { return self.possibleDurations.index(of: self.duration) }
        set (value)
        {
            self.duration = self.possibleDurations[value!]
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.commonInit()
        self.configureAccessibility()
        self.durationSlider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        self.refreshUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.commonInit()
    }
    
    // snap to nearest possible value
    private func inrement(){
        if (self.durationSlider.value < self.durationSlider.maximumValue){
            if let index = self.durationIndex{
                self.durationIndex = index+1
                self.refreshUI()
            }
        }
    }
    private func decrement(){
        if (self.durationSlider.value > self.durationSlider.minimumValue){
            if let index = self.durationIndex{
                self.durationIndex = index  - 1
                self.refreshUI()
            }
        }
    }
    
    private func commonInit(){
        self.configureAccessibility()
        self.durationSlider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        self.refreshUI()
    }

    // could use NSDateComponentFormatter instead to create duration strings. But the 
    //  rest of the UI is not localized, so localizing duration strings only would be 
    //  awkward. DateComponentsFormatter does not seem to allow fixed locales (why?), 
    //  so let's get duration strings manually:
    private func durationString() -> String{
        return "\(self.duration) sec"
    }
    private func longDurationString() -> String{
        if ( duration < 1){
            return "\(self.duration) seconds"
        }
        else if (duration == 1){
            return "1 second"
        }
        else{
            return "\(Int(self.duration)) seconds"
        }
    }
    
    private func refreshUI(){
        if let index : Int = self.possibleDurations.index(of: self.duration){
            let stepCount : Int = self.possibleDurations.count-1
            self.durationSlider.value = Float(index) / Float(stepCount)
        }
        self.durationLabel.text = self.durationString()
        self.durationLabel.accessibilityLabel = self.longDurationString()
    }
    
    @objc private func valueChanged(){
        if (self.possibleDurations.count == 0) { return }
        
        // snap to nearest defined duration
        let stepCount : Int = self.possibleDurations.count-1
        let closestStep : Int = Int(round (self.durationSlider.value * Float(stepCount) ))
        self.durationIndex = closestStep
        self.refreshUI()
    }
    
    // MARK: voice over accessibility
    private func configureAccessibility(){
        self.isAccessibilityElement = true
        self.accessibilityLabel = "Duration"
        self.accessibilityTraits = UIAccessibilityTraitAdjustable
    }
    
    override var accessibilityValue: String?{
        get { return self.durationLabel.accessibilityLabel }
        set(value) { self.durationLabel.accessibilityLabel = value }
    }
    override func accessibilityActivate() -> Bool {
        return self.durationSlider.accessibilityActivate()
    }

    override func accessibilityIncrement() {
        self.inrement()
    }
    override func accessibilityDecrement() {
        self.decrement()
    }
}
