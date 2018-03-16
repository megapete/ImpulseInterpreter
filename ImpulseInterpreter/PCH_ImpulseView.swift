//
//  PCH_ImpulseView.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2018-02-14.
//  Copyright © 2018 Huberis Technologies. All rights reserved.
//

import Cocoa

// // local defines
fileprivate let xAxisInset:CGFloat = 5.0 // same left and right
fileprivate let yAxisInset:CGFloat = 5.0 // same bottom and top
fileprivate let xAxisLabelsSpace:CGFloat = 15.0
fileprivate let yAxisLabelsSpace:CGFloat = 25.0

class PCH_ImpulseView: NSView {
    
    @IBOutlet weak var bottomLabel: NSTextField!
    @IBOutlet weak var topLabel: NSTextField!
    
    var yLabelArray:[NSTextField] = []
    
    var origin:(x:CGFloat, y:CGFloat) = (xAxisInset + yAxisLabelsSpace, yAxisInset + xAxisLabelsSpace)
    var scale:(x:CGFloat, y:CGFloat) = (1.0, 1.0)
    var yData:[Double] = []
    var yAxisExtremes:(bottom:Double, top:Double) = (0.0, 0.0)
    
    var axesNeedDisplay = true
    
    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)
        
        guard self.yData.count > 0 else
        {
            return
        }
        
        if (self.axesNeedDisplay)
        {
            // Draw the axes
            NSColor.black.setStroke()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: self.origin.x, y: yAxisInset))
            path.line(to: NSPoint(x: self.origin.x, y: self.bounds.height - yAxisInset))
            path.move(to: NSPoint(x: xAxisInset, y: self.origin.y))
            path.line(to: NSPoint(x: self.bounds.width - xAxisInset, y: self.origin.y))
            path.stroke()
            
            path.removeAllPoints()
            
            self.bottomLabel.frame = NSRect(origin: NSPoint(x: self.origin.x + 2.0, y: self.origin.y - self.bottomLabel.bounds.height - 2.0), size: self.bottomLabel.frame.size)
            self.bottomLabel.needsDisplay = true
            
            self.topLabel.frame = NSRect(origin: NSPoint(x: self.bounds.width - xAxisInset - self.topLabel.bounds.width, y: self.origin.y - self.topLabel.bounds.height - 2.0), size: self.topLabel.frame.size)
            self.topLabel.needsDisplay = true
            
            for nextLabel in self.yLabelArray
            {
                nextLabel.removeFromSuperview()
            }
            
            self.yLabelArray = []
            
            var currentCenterY = yAxisInset
        
            self.axesNeedDisplay = false
        }
        
        
        

        // Draw the voltages that are currently in the yData array using the current scale and origin
    }
    
    func SetScaleAndOrigin(numNodes:Int, yMin:Double, yMax:Double)
    {
        let overallXspace = self.bounds.width - 2.0 * xAxisInset - yAxisLabelsSpace
        let overallYspace = self.bounds.height - 2.0 * yAxisInset
        
        self.scale.x = overallXspace / CGFloat(numNodes - 1)
        
        let yBottomValue = min(0.0, floor(yMin / 50000.0) * 50000.0)
        yAxisExtremes.bottom = yBottomValue
        let yTopValue = ceil(yMax / 50000.0) * 50000.0
        yAxisExtremes.top = yTopValue
        
        self.scale.y = overallYspace / CGFloat(yTopValue - yBottomValue)
        
        self.origin.y = yAxisInset + xAxisLabelsSpace - CGFloat(yBottomValue) * self.scale.y
        
        self.axesNeedDisplay = true
    }
    
}
