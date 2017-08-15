//
//  UIViewInterpolatedAnimation.swift
//  GameTimer
//
//  Created by Rolf Hendriks on 5/8/17.
//
//

import Foundation
import UIKit


/**
 Implements a minimalist API for maximally flexible animations by hooking into
 a callback method that gets executed each animation frame:

 RHAnimator.animate( duration:1 animation:{ progress in ... })
 
 Optionally supports fully customizable animation curves. Animation curves are an arbitrary
 function, again supporting maximum flexibility with a minimalist API:
 
 let fastAcceleration = { x in x*x*x }
 RHAnimator.animate( duration:1 curve:fastAcceleration animation: { progress in ... } )

 Also includes a utility for easily computing interpolated values for animations:
 animation: {  
    progress in
    updatedValue = RHAnimator.interpolate( from:startValue to:endValue at:progress )
 }
 
 LIMITATIONS:
 
 No support for automatically interpolating between beginning + final animated value.
 Instead, you will need to calculate the animated value each frame. RHAnimator provides
 an interpolation utility that should make this straightforward though.
 
 RHAnimator updates properties continuously instead of distinguishing
 logical vs rendered properties like UIView animations do. For example, let's say
 we are querying a view that is midway through a fade in animation. Using UIKit, 
 view.alpha == 1, while with RHAnimator, view.alpha == 0.5. Which of these two is the 
 expected behavor depends on context, but usually UIKit's approach is more convenient.
 
 No support for pausing + resuming an animation. Instead, animations fast forward
 to their end when canceled. Pause + resume would be easy to add if needed.
 
 No support for advanced UIKit animation features such as autoreverse, repeat, etc.
 
 Only one animator may be active per object property. The behavior for running multiple
 animators on the same property is undefined. This limitation also applies to UIKit animations.
 */

open class RHAnimator : NSObject
{
    // these aliases improve code legibility but turn out to have drawbacks as well:
    //  * can complicate code completion, because code completion will show the 
    //    type aliases instead of the underlying types
    //  * breaks potential compatibility with Objective C
    // Because of code completion, RHAnimator does not use these typedefs in its own 
    // function definitions. They are still available for consumers to use as needed.
    typealias Interpolation = (Double) -> Double
    typealias AnimationClosure = (_ progress:Double)->Void
    
    /**
    Begins an animation with configurable animation logic
    @param duration the animation duration in seconds
    @param animation the animation logic to execute each frame. 
        Supplies a parameter representing the animation progress, 
        from 0 = start of animation to 1 = end of animation.
    */
    @discardableResult static func animate ( duration : TimeInterval, animation : @escaping (_ progress:Double)->Void, completion: ((Void)->Void)? = nil ) -> RHAnimator
    {
        return animate(duration: duration, curve: nil, animation:animation, completion:completion )
    }
    
    /**
    Begins an animation with configurable animation logic and curve.
    @param curve an animation curve represented as a function.
     function inputs range from 0 = animation start time to 1 = animation end time.
     outputs range from 0 = initial value to 1 = final value. Some curves, such as an overshoot 
     animation, may return values outside of the typical 0-1 range.
    @see RHAnimationCurves for sample animation curves
     */
    @discardableResult static func animate ( duration : TimeInterval, curve : ((Double)->Double)?, animation :  @escaping (_ progress:Double)->Void, completion: ((Void)->Void)? = nil ) -> RHAnimator {
        return RHAnimator(duration: duration, animation: animation, curve: curve, completion:completion).start()
    }
    
    // WARNING: use generic interpolate function
    
    /** 
    Utility method to compute an interpolated value.
    @param from the value at start of animation / progress==0
    @param to the value at the end of the animation / progress==1
    @param at animation progress, from 0=start to 1=end of animation
    */
    static func interpolate<T : Interpolatable> (from: T, to:T, at:Double) -> T {
        return from * (1-at) + to * at
    }
    
    /**
    Stops an existing animation, which fast-forwards the animation to its end.
    May want to add other ways to interrupt an animation as needed in the future.
    */
    func stop(){
        if (self.isRunning) {
            self.finished()
        }
    }
    
    var isRunning : Bool { return self.startTime != 0 }
    
    
    //////////////////////////////////////// PRIVATE
    // MARK: PRIVATE
    
    private let animation : (_ progress:Double)->Void
    private let interpolation : ((Double) -> Double)?
    private let completion : ((Void)->Void)?
    
    private var startTime : TimeInterval = 0
    private var duration : TimeInterval = 0
    
    private var displayLink : CADisplayLink?
    
    /**
     @param animation the logic to execute each frame of the animation. progress = input value ranging from 0 = start of animation to 1 = end of animation.
     @param curve the animation curve to apply. Should be a function from (0,0) to (1,1). Uses linear interpolation if omitted.
     */
    private init( duration : TimeInterval, animation:@escaping(_ progress:Double)->Void, curve : ((Double) -> Double)?, completion:((Void)->Void)? ){
        self.animation = animation
        self.interpolation = curve
        self.completion = completion
        self.duration = duration
    }
    
    private func start() -> RHAnimator{
        self.startTime = NSDate.timeIntervalSinceReferenceDate
        
        // special case: zero duration animation. Go straight to finished logic
        if (self.duration == 0){
            self.finished()
        }
        else{
            self.displayLink = CADisplayLink(target: self, selector: #selector(tick))
            self.displayLink!.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
        }
        return self
    }
    
    @objc private func tick(){
        let elapsed : TimeInterval = NSDate.timeIntervalSinceReferenceDate - self.startTime

        // special case: finishing animation. Be sure to explicitly call the animation function with
        //  progress == 1.0:
        if (elapsed >= self.duration) // termination condition also catches duration == 0, which would otherwise cause a divide by zero error
        {
            finished()
            return
        }
        
        var t : Double = elapsed / self.duration
        
        // interpolate
        if let interpolation = self.interpolation{
            t = interpolation(t)
        }
        
        // callback
        self.animation(t)
    }
    
    // edge case: it's possible to use an interpolation that does not end at (1,1).
    //  so instad of assuming/hardcoding that all animations end at y==1, we query
    //  our animation curve for its final value.
    private func finalInterpolatedValue() -> Double {
        return self.interpolation != nil ? self.interpolation!(1.0) : 1.0
    }
    
    private func finished(){
        self.animation(self.finalInterpolatedValue())
        if let completion = self.completion{
            completion()
        }
        self.startTime = 0
        
        if let displayLink = self.displayLink{
            displayLink.invalidate()
            self.displayLink = nil
        }
    }
}

// Any object implementing intepolatable can easily be animated as follows:
//  newValue = RHAnimator.interpolate( from:startValue to:endValue by:progress )
// Note: the future 'Numeric' Swift4 protocol looks like a promising substitute for this.
protocol Interpolatable{
    static func + (lhs: Self, rhs:Self) -> Self
    static func * (lhs: Self, rhs:Double) -> Self
}
extension Float : Interpolatable{
    static func *(lhs: Float, rhs: Double) -> Float {
        return lhs * Float(rhs)
    }
}
extension CGFloat : Interpolatable{
    static func *(lhs: CGFloat, rhs: Double) -> CGFloat {
        return lhs * CGFloat( rhs )
    }
}
extension Double : Interpolatable{}

// bonus: make Core Graphics structures interpolatable
extension CGPoint : Interpolatable{
    static func *(lhs: CGPoint, rhs: Double) -> CGPoint {
        return CGPoint( x:lhs.x * CGFloat(rhs), y:lhs.y * CGFloat(rhs))
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint( x:lhs.x + rhs.x, y:lhs.y + rhs.y )
    }
}
extension CGSize : Interpolatable{
    static func *(lhs: CGSize, rhs: Double) -> CGSize {
        return CGSize( width:lhs.width * CGFloat(rhs), height:lhs.height * CGFloat(rhs))
    }
    
    static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize( width:lhs.width + rhs.width, height:lhs.height + rhs.height )
    }
}

// could add support for CGRect + CGAffineTransform, but the result would
// be confusing. Animate positions, sizes, rotations, etc directly
// using numeric/point/size interpolations instead.
