//
//  RHFunctionGraphView.swift
//  RHAnimator
//
//  Created by Rolf Hendriks on 8/12/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

import UIKit

/**
 Lightweight implementation of a graphing calculator type UI for showing 
 a mathemetical x/y function in 2D 
 */
class RHFunctionGraphView: UIView {

    // MARK: Initialization + Configuration
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = false
        self.setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.clipsToBounds = false
        self.setNeedsDisplay()
    }
    
    // WARNING: fix escaping/nonescaping issue
    func setFunction(_ function:@escaping (Double)->Double){
        self.function = function
        self.setNeedsDisplay()
    }
    
    func setDomainAndRange(_ domainAndRange : CGRect ){
        if (domainAndRange != self.domainAndRange){
            self.domainAndRange = domainAndRange
            self.setNeedsDisplay()
        }
    }
    
    // MARK: Styling
    struct LineStyle{
        var lineWidth : CGFloat = 1
        var color : UIColor = UIColor.black
    }
    
    var axisLineStyle : LineStyle = LineStyle( lineWidth:4, color:UIColor.black)
    var functionLineStyle : LineStyle = LineStyle (lineWidth: 2, color: UIColor.blue)
    var gridLineStyle : LineStyle = LineStyle( lineWidth:1.0, color:UIColor.lightGray)
    var majorGridLineStyle : LineStyle = LineStyle( lineWidth:2, color:UIColor.gray )
    
    /// set to nonzero value to draw a grid line every x logical units
    func setGridLineInterval (x:Double, y:Double){
        self.gridLineIntervalX = x
        self.gridLineIntervalY = y
        self.setNeedsDisplay()
    }
    
    /// set to nonzero value to draw a major grid line every n minor grid lines
    func setMajorGridLineInterval( count:Int ){
        self.majorGridLineInterval = count
        self.setNeedsDisplay()
    }
    
    /////////////////////////////// PRIVATE
    // MARK:PRIVATE
    
    /// The function to graph
    private var function : (Double)->Double = { x in x }
    
    /**
     The range of x and y values to graph for the specified function
     */
    private var domainAndRange : CGRect = CGRect (x: 0, y: 0, width: 1, height: 1)

    private var gridLineIntervalX : Double = 0
    private var gridLineIntervalY : Double = 0
    private var majorGridLineInterval : Int = 0
    
    private var graphScaleX : Double = 1 // how many horizontal pixels per logical x unit of the graph
    private var graphScaleY : Double = 1
    private var maximumLineThickness : CGFloat {
        return max ( self.functionLineStyle.lineWidth, self.axisLineStyle.lineWidth )
    }
    
    override var bounds: CGRect {
        didSet {
            let sizeChanged : Bool = oldValue.size != self.frame.size
            if (sizeChanged){
                self.setNeedsDisplay()
            }
        }
    }

    override func draw(_ rect: CGRect) {
                
        // setup
        let w : CGFloat = self.bounds.width
        let h : CGFloat = self.bounds.height
        let context : CGContext = UIGraphicsGetCurrentContext()!
        self.graphScaleX = Double (w / self.domainAndRange.width)
        self.graphScaleY = Double (h / self.domainAndRange.height)
        
        // setting CTM. This gets a bit confusing.
        // For axis orientation, we want to keep the Core Graphics convention of (0,0) == 
        // BOTTOM left corner, not UIKit convention of (0,0) == TOP left corner.
        // This was once the default behavior in drawRect:, but the default changed to using 
        // UIKit coordinates instead.
        // WARNING: find out when this was changed
        context.translateBy(x: 0, y: h)
        context.scaleBy(x:1, y:-1)
        
        // fix: prevent lines from appearing partially out of bounds due to line thickness.
        // A quick + dirty way to do this is to modify the CTM to leave space for an additional half 
        // stroke width of content on all four sides:
        let halfStrokeWidth : CGFloat = self.maximumLineThickness/2
        let extendedWidth : CGFloat = w + 2*halfStrokeWidth
        let extendedHeight : CGFloat = h + 2*halfStrokeWidth
        context.translateBy(x: halfStrokeWidth, y: halfStrokeWidth)
        context.scaleBy(x: w/extendedWidth, y:h/extendedHeight)
        
        self.drawGridLines(context: context)
        self.drawFunction(context: context)
    }
    
    private func drawGridLines( context: CGContext ){
        // draw vertical grid lines
        self.applyStyle(self.gridLineStyle, context: context)
        if (self.gridLineIntervalX > 0){
            var tickNumber : Int = Int( ceil (Double(self.domainAndRange.minX) / self.gridLineIntervalX) ) // position of first vertical line to draw, as tick mark offset from y axis
            let firstTickValue : Double = Double(tickNumber) * self.gridLineIntervalX // x value of leftmost tick mark. This is xMin unless tick marks don't align with the graph's bounds
            let firstTickOffset : CGFloat = self.xPositionForValue(firstTickValue)
            let tickSpacing : CGFloat = CGFloat(self.gridLineIntervalX * self.graphScaleX)
            for offset : CGFloat in stride(from: firstTickOffset, through: self.bounds.width, by: tickSpacing){
                // handle major/minor grid lines
                if (self.majorGridLineInterval > 0){
                    let lineStyle : LineStyle = tickNumber % self.majorGridLineInterval == 0 ? self.majorGridLineStyle : self.gridLineStyle
                    self.applyStyle(lineStyle, context: context)
                }
                self.drawVerticalLine(context: context, x: offset)
                tickNumber += 1
            }
        }
        // draw horizontal grid lines
        if (self.gridLineIntervalY > 0){
            var tickNumber : Int = Int( ceil (Double(self.domainAndRange.minY) / self.gridLineIntervalY) ) // position of first horizontal line to draw, as tick mark offset from x axis
            let firstTickValue : Double = Double(tickNumber) * self.gridLineIntervalY // y value of bottom most tick mark. This is yMin unless tick marks don't align with the graph's bounds
            let firstTickOffset : CGFloat = self.yPositionForValue(firstTickValue)
            let tickSpacing : CGFloat = CGFloat(self.gridLineIntervalY * self.graphScaleY)
            for offset : CGFloat in stride(from: firstTickOffset, through: self.bounds.height, by: tickSpacing){
                // handle major/minor grid lines
                if (self.majorGridLineInterval > 0){
                    let lineStyle : LineStyle = tickNumber % self.majorGridLineInterval == 0 ? self.majorGridLineStyle : self.gridLineStyle
                    self.applyStyle(lineStyle, context: context)
                }
                self.drawHorizontalLine(context: context, y: offset)
                tickNumber += 1
            }
        }
        
        // draw axes
        let yAxisOffset : CGFloat = self.xPositionForValue(0)
        let xAxisOffset : CGFloat = self.yPositionForValue(0)
        self.applyStyle(self.axisLineStyle, context: context)
        self.drawVerticalLine(context: context, x: yAxisOffset)
        self.drawHorizontalLine(context: context, y: xAxisOffset)
    }
    
    private func drawFunction( context: CGContext ){
        // Let's use a simple/naive algorithm that just computes a y coordinate for
        // each x coordinate. For all practical purposes, this should be good enough.
        // Some potential limitations we are not addressing are:
        //  * cannot render functions that have multiple y values for one x pixel
        //      (ex: circle function, representing samples instead of a
        //      mathemetical function, function with etremely squished x axis)
        //  * rendering of local maxima + minima will not be 100% accurate. For example
        //      if drawing a horizontally squished sine wave, minima + maxima of each wave
        //      may not line up exactly.
        //  * overall result may be extremely unoptimized. We may end up with hundreds of
        //      line segments for a curve that could be represented in one or two bezier
        //      curves instead.
        self.applyStyle(self.functionLineStyle, context: context)
        context.beginPath()
        let pixelWidth : CGFloat = 1.0 / self.contentScaleFactor
        for xPixel in stride(from: 0.0, to: self.bounds.width, by: pixelWidth) {
            let x : Double = self.xValueForPosition(xPixel)
            let y : Double = self.function(x)
            let yPixel : CGFloat = self.yPositionForValue(y)
            if (xPixel == 0.0) {
                context.move(to: CGPoint(x:xPixel, y:yPixel))
            }
            else{
                context.addLine(to: CGPoint(x:xPixel, y:yPixel))
            }
        }
        context.strokePath()
    }
    
    // MARK: Utils
    private func drawVerticalLine ( context:CGContext, x: CGFloat ){
        let halfLineThickness : CGFloat = self.maximumLineThickness/2
        context.drawLine(CGPoint( x:x, y:-halfLineThickness), CGPoint( x:x, y:self.bounds.height))
    }
    
    private func drawHorizontalLine ( context: CGContext, y:CGFloat ){
        let halfLineThickness : CGFloat = self.maximumLineThickness/2
        context.drawLine( CGPoint( x:-halfLineThickness, y:y ), CGPoint( x:self.bounds.width, y:y ) )
    }
    
    private func applyStyle (_ style : LineStyle, context:CGContext ){
        style.color.setStroke()
        context.setLineWidth(style.lineWidth)
    }
    
    // convert between logical x/y coordinates (units defined by the function we
    //  are graphing) and UI x/y coordinates (1 unit = 1 device pixel).
    // UI x/y coordinates are measured from BOTTOM left corner, using
    //  Core Graphics instead of UIKit conventions.
    private func xValueForPosition (_ xPixel: CGFloat ) -> Double{
        return Double(self.domainAndRange.minX) + Double(xPixel) / self.graphScaleX
    }
    private func yValueForPosition (_ yPixel: CGFloat ) -> Double{
        return Double(self.domainAndRange.minY) + Double(yPixel) / self.graphScaleY
    }
    private func xPositionForValue (_ xValue: Double ) -> CGFloat{
        return CGFloat( xValue * self.graphScaleX ) - self.domainAndRange.minX
    }
    private func yPositionForValue (_ yValue: Double ) -> CGFloat{
        return CGFloat(self.graphScaleY) * ( CGFloat(yValue) - self.domainAndRange.minY)
    }
}

extension CGContext
{
    func drawLine (_ from: CGPoint, _ to:CGPoint){
        self.beginPath()
        self.move( to:from )
        self.addLine( to:to )
        self.strokePath()
    }
}
