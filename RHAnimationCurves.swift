//
//  RHAnimationCurves.swift
//  RHAnimator
//
//  Created by Rolf Hendriks on 8/11/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

import Foundation

class RHAnimationCurves
{
    // MARK: - UIKit animation curve equivalents
    
    /// curve with acceleration at beginning and deceleration at end of animation
    static var easeInOut : (Double)->Double = {
        return 0.5 * (1 - cos($0 * Double.pi))
    }

    /// curve with acceleration at beginning of animation
    static var easeIn : (Double)->Double = {
        return 1 - cos ($0 * Double.pi / 2)
    }

    /// curve with deceleration at end of animation
    static var easeOut : (Double)->Double = {
        return sin ($0 * Double.pi / 2)
    }
    
    static var linear : (Double)->Double = {
        return $0
    }

    // MARK: - Parameterized acceleration + deceleration
    
    /*
        Configurable easing curves intended for more pronounced 
        acceleration + deceleration. Uses x^n function
        internally, where n is configurable. Default UIKit curves 
        are sinusoidal, which is slightly weaker than x^2.
     */
    
    /** 
        @param strength acceleration strength
        @return easeIn function with the passed in strength
     */
    static func accelerate( strength: Double) -> (Double)->Double {
        return { (x:Double) in strength == 2 ? x*x : pow( x, strength ) }
    }
    
    /**
     @param strength deceleration strength
     @return easeOut function with the passed in strength
     */
    static func decelerate( strength: Double) -> (Double)->Double {
        return opposite(function: self.accelerate(strength: strength))
    }
    
    /**
    @param strength acceleration + deceleration strength
    @return easeInOut function with the passed in strength
     */
    static func ease ( strength: Double ) -> (Double)->Double {
        let accelerate : (Double)->Double = self.accelerate(strength: strength)
        let decelerate : (Double)->Double = self.opposite(function: accelerate)
        return self.compose( accelerate, decelerate )
    }

    // MARK: - Overshoot / Oscillation
    
    /**
    Overshoots the target one or more times using a harmonic oscillation curve, 
     with end results similar to UIKit spring animations. However these animations 
     are easier to tweak, allowing for an exact animation duration and number of 
     overshoots.
    @param count how many times to go back + forth over the final value.
    @param halflife how quickly the oscillation should decay. See exponential 
        deceleration for details.
    */
    static func overshoot ( count: Int = 1, halflife : Double = 0.15 ) -> (Double)->Double {
        return { (x : Double) in
            // ensure animation always ends at y=1 like normal curves do
            if (x >= 1) { return 1 }
            
            //
            // want an animation that begins at (0,0), ends at (1,1), and oscillates
            //  back and forth around y = 1. But how?
            //
            //  IDEA: create a function from (0,-1) to (0,0) oscillating around y=0,
            //  by using a sinusoidal wave multiplied by exponential decay. Then add 1.
            //
            
            // use a -cos curve to produce oscillations.
            //  0 overshoots = 1/4 curve
            //  1 overshoot = 3/4 curve
            //  n overshoots = n/2 + 1/4 = (2n+1)/4
            let waveCount : Double = 0.25 + 0.5 * Double(count);
            let waveValue : Double =  (-cos ( 2.0 * Double.pi * x *
            waveCount) );
            let halflifeCount : Double = x / halflife
            let exponentialDecayValue : Double = pow (0.5, halflifeCount);
            return  1.0 + exponentialDecayValue * waveValue;
        }
    }

    // MARK: - Exponential deceleration
    static func exponentialDecelerate( halflife: Double = 0.15 ) -> (Double)->Double {
        return { (x : Double) in
            // ensure animation always ends at y=1 like normal curves do
            if (x >= 1) { return 1 }
            let halflifeCount : Double = x / halflife
            return 1.0 - pow ( 0.5, halflifeCount )
        }
    }
    
    static func decay( halflife:Double = 0.15 ) -> (Double)->Double {
        return{ (x : Double) in
            let halflifeCount : Double = x / halflife
            return pow( 0.5, halflifeCount )
        }
    }
    
    // MARK: - Utils
    
    /** 
     given an animation curve, find an animation curve that matches it in the opposite
     direction. For example, given an ease in curve, return a matching ease out curve.
     
     This is similar but not identical to an inverse function. For the sake of animations,
     an opposite function is better than an inverse function because the returned function
     mirrors the original's behavior. So if the original started slowly, the
     opposite function will end slowly. We can also compose a function and its opposite
     without discontinuities, which is not true for composing a function and its inverse.
     */
    static func opposite ( function: @escaping (Double)->Double ) -> (Double)->Double {
        return {
            (x : Double) in
            return 1 - function(1-x)
        }
    }
    
    /** 
    Given two independent animation curves, return an animation curve that applies
    the 1st curve in the 1st half of the animation and the 2nd curve in the 2nd half
    */
    static func compose (_ function1: @escaping (Double)->Double, _ function2: @escaping (Double)->Double ) -> (Double)->Double {
        return { (x : Double) in
            if (x <= 0.5) { return 0.5 * function1(2*x) } // function from (0,0) to (0.5,0.5)
            else { return 0.5 + 0.5 * function2( 2*(x-0.5) ) } // function from (0.5,0.5) to (1,1)
        }
    }
}
