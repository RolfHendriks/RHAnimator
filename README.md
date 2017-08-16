# RHAnimator
Swift based fully customizable animation curves

<img alt="RHAnimator screenshot" src="https://user-images.githubusercontent.com/539554/29385582-397455fe-82a6-11e7-8f45-b53eb5e1fb47.png" width="320" height="568">

## Overview

This project consists of three parts:
1. **RHAnimator**, a simple low level utility for implementing any custom animation
2. **RHAnimationCurves**, a companion utility that defines a variety of custom animation curves not found in UIKit
3. A detailed demo project to showcase RHAnimator+RHAnimationCurves and to serve as a sample project for professional grade iOS app development.

## RHAnimator Basics

RHAnimator provides an extremely simple and flexible low level animation API that calls an update method once every animation frame. For example:

    RHAnimator.animate( duration:1 animations:
    {   
      (progress : Double) in // progress begins at 0 and ends at 1  
  
      // example - simple fade in:
      view.alpha = progress
  
      // example - play a frame by frame custom animation:
      let frameNumber : Int = Int( round (progress * self.animationFrames.count - 1) )
      imageView.image = self.animationFrames[frameNumber]
  
      // example - blink 10 times, slowly at first then quickly, ending at visible:
      let acceleratedTime : Double = progress * progress
      let onOffCount : Int = Int ( acceleratedTime * 19 )
      blinker.hidden = (onOffCount % 2 == 0)
  
      // etc, etc
    }

Although RHAnimator could replace UIKit animations in a project, this is not the intent. Instead, RHAnimator is intended for game-like rich custom animations outside of the scope of UIKit, including animating unanimatable properties and using nonstandard animation curves.

## RHAnimationCurves Basics

One of the main use cases for RHAnimator is to get more customizable animation curves than UIKit allows. For example, to eject a view from the screen using an unusually strong acceleration, you could do this:

    let strongAcceleration : (Double)->Double = { x in return x*x*x }
    RHAnimator.animate( duration:1 curve:strongAcceleration animations{ 
      progress in 
      view.transform = CGAffineTransform (translationX: CGFloat(progress * 100), y:0 )
    })

In UIKit, we need to create animation curves by defining key frames. In RHAnimator, an animation curve is simply a function, so you can implement any animation curve you want, often in a single line of code.

If custom animation curves are your reason for using RHAnimator, **RHAnimationCurves** provides a wide variety of useful premade curves, which the demo app shows off in detail. Because this is a feature you may or may not need, RHAnimationCurves is a separate component from RHAnimator so that RHAnimator keeps its minimalist size.



## Technical Details

### Using CADisplayLink

RHAnimator uses **CADisplayLink** internally to manage its timing for maximum performance. CADisplayLink syncronizes with iOS's screen refreshing logic and guarantees that our animation logic gets called exactly once per screen update. This means that if iOS changes their refresh rate, as they have recently done with iOS11, RHAnimator will still work at full speed. And if the screen refresh rate is reduced to conserve battery life or because the system is overloaded, RHAnimator will slow down its updates automatically.

### Landscape Layout using UIStackView

This demo uses an interesting layout trick to alter the UI in landscape orientation so that the function graph is on the right half of the screen instead of the bottom. This trick was inspired by experimenting with responsive web site design using CSS flex grids.

The screen layout uses a two element **UIStackView** to lay out a 50/50 split between the bottom half of the screen, displaying a function graph, and the top half of the screen, displaying everything else.

When the screen orientation changes, the stackView changes its layout direction. The result is that the 50/50 split is now horizontal, with the function graph to the right half of the screen and everything else to the left half. Thanks to UIStackView, this all happens by changing a single property on a single view.

### Robust interpolations using the Interpolatable protocol

One of the most common tasks for custom animations is interpolating values: given the state at the start of the animation, the desired end state, and the currently elapsed time, what should the new state be?

A typical C approach might look like this:

    #define interpolate( from,to,at ) ((from)*(1-at) + (to)*(at))

It's a concise solution, but also unsafe, inflexible, and unSwifty. Instead, RHAnimator formalizes the idea of interpolation into a protocol:

    protocol Interpolatable{
      static func + (lhs: Self, rhs:Self) -> Self
      static func * (lhs: Self, rhs:Double) -> Self
    }
    static func interpolate<T : Interpolatable> (from: T, to:T, at:Double) -> T {
      return from * (1-at) + to * at
    }

RHAnimator then defines Interpolatable implementations for numbers, points, and sizes. More important though, the Interpolatable protocol allows you to animate your own custom data structures - as long as they implement scaling and addition.

### Interpolation Function Composition

The RHAnimationCurves utility defines not just curves, but methods for generating curves more easily. For example, look at the implementation of a parameterized easeInOut curve:

    static func ease ( strength: Double ) -> (Double)->Double {
        let accelerate : (Double)->Double = self.accelerate(strength: strength)
        let decelerate : (Double)->Double = self.opposite(function: accelerate)
        return self.compose( accelerate, decelerate )
    }

### Custom Animation Curves

#### Exponential Deceleration / Slowdown

An exponential deceleration curve is an excellent choice any time you want an object to come to rest from a moving state because it matches the physics of a real object slowing to a stop. iOS uses exponential deceleration curves when scroll views slow down, but unfortunately does not expose them in any API. So if you want to use exponential deceleration, RHAnimator combined with RHAnimationCurves.decelerate is one possible solution.

#### Configurable Easing

iOS defines curves for easing in, out, or both, but iOS's curves are subtle and not configurable. RHAnimationCurves defines paramterized easing functions that are similar, but allow the amount of easing to be configured to create more pronounced curves.

#### Configurable Overshoot

RHAnimationCurves.overshoot defines a parameterized overshoot curve that behaves very similar to UIKit's spring animation API. This custom overshoot implementation is unusually tweakable, allowing for an exact number of overshoots. And since RHAnimator can animate anything, the overshoot curve allows you to bring spring animations to unanimatable properties.

#### UIKit Curve Replicas

RHAnimationCurves defines exact replicas of UIKit's four animation curves (easeInOut, easeIn, easeOut, linear). These are useful if you want to apply a standard easing function to animate a custom property.
