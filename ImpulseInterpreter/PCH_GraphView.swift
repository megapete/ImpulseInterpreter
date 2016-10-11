//
//  PCH_GraphView.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-22.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_GraphView: NSView {
    
    /// A constant that moves the graph a bit inside the window
    let inset = CGFloat(50.0)
    
    var numYlabels = 10
    
    var bottomLabel:NSTextField?
    var topLabel:NSTextField?
    
    /// The app controller object
    weak var theController:PCH_AppController?
    
    /// The current scaling factors of the view
    var currentScale:(x:Double, y:Double) = (1.0, 1.0)
    
    /// A bool to help with not doing too many redraws of stuff that doesn't change
    var scaleChanged = true
    
    /// An array to hold the subviews that show the yLabels (needed for erasing when changes occur)
    var yLabelArray:[NSTextField]? = nil
    
    var voltages:[Double]?
    
    /// Function to calculate the scale factors for the graph
    func ZoomAll()
    {
        guard let appCont = self.theController
        else
        {
            return
        }
        
        let xNodes = 1.0 * CGFloat((appCont.getCoilNodeIDs().count))
        
        if xNodes == 0.0
        {
            return
        }

        currentScale.x = Double((xNodes - 1.0) / (self.frame.size.width - 2.5 * inset))
        
        let extremes = appCont.getCoilExtremeVoltages()
        
        // round up the max extreme to the next 50kV (same for min, but round down)
        let yMax = round(extremes.maxV / 50000.0 + 0.5) * 50000.0
        let yMin = round(extremes.minV / 50000.0 - 0.5) * 50000.0
        
        // Set the number of labels so we get one every 20kV
        self.numYlabels = Int((yMax - yMin) / 50000) + 1
        let yOverall = /* 1.05 * */ CGFloat(yMax - yMin)
        
        currentScale.y = Double(yOverall / (self.frame.size.height - 3.0 * inset))
        
        scaleChanged = true
    }
    
    override func viewDidMoveToSuperview()
    {
        DLog("We came here")
    }
    
    /// Override of the drawing method
    override func draw(_ dirtyRect: NSRect)
    {
        // required call to super func
        super.draw(dirtyRect)
        
        guard let appCont = self.theController
        else
        {
            return
        }
        
        // Drawing code here.
        // Draw the axes. The Y-axis is always located at the left of the window so we'll start with that.
        NSColor.black.set()
        let path = NSBezierPath()
        path.move(to: NSMakePoint(inset * 1.5, inset / 2.0))
        path.line(to: NSMakePoint(inset * 1.5, self.frame.size.height - inset))
        path.stroke()
        
        let extremes = appCont.getCoilExtremeVoltages()
        var xAxisHeight = CGFloat(0.0)
        
        if (appCont.numericalData != nil)
        {
            let yMin = round(extremes.minV / 50000.0 - 0.5) * 50000.0
            
            xAxisHeight -= CGFloat(yMin)
        }
        
        path.removeAllPoints()
        path.move(to: NSMakePoint(inset * 1.3 /* / 2.0 */, inset * 1.5 + xAxisHeight / CGFloat(currentScale.y)))
        path.line(to: NSMakePoint(self.frame.size.width - inset, inset * 1.5 + xAxisHeight / CGFloat(currentScale.y)))
        path.stroke()
        
        let origin:NSPoint = NSMakePoint(inset * 1.5, inset * 1.5 + xAxisHeight / CGFloat(currentScale.y))
        
        bottomLabel?.frame = NSRect(x: origin.x + 2.0, y: origin.y - bottomLabel!.frame.height - 2.0, width: bottomLabel!.frame.width, height: bottomLabel!.frame.height)
        topLabel?.frame = NSRect(x: self.frame.size.width - inset - topLabel!.frame.width / 2.0, y: origin.y - topLabel!.frame.height - 2.0, width: topLabel!.frame.width, height: topLabel!.frame.height)
        
        
        if (appCont.numericalData == nil)
        {
            return
        }
        
        if scaleChanged
        {
            if (yLabelArray != nil)
            {
                for nextView in yLabelArray!
                {
                    nextView.removeFromSuperview()
                }
            }
            
            var yPos = self.frame.size.height - inset * 1.5 - 5.0
            let yOffset = (self.frame.size.height - 3.0 * inset) / CGFloat(numYlabels - 1)
            let kvMax = round(extremes.maxV / 50000.0 + 0.5) * 50000.0
            let kvMin = round(extremes.minV / 50000.0 - 0.5) * 50000.0
            let kvPerTick = 50000.0
            var kvCurrent = kvMax
            
            yLabelArray = Array()
            
            for i in 0..<numYlabels
            {
                if #available(OSX 10.12, *)
                {
                    let theKV = "\(Int(kvCurrent / 1000.0))kV"
                    let nextField = NSTextField(labelWithString: theKV)
                    nextField.isEditable = false
                    nextField.isBezeled = false
                    nextField.isBordered = false
                    nextField.alignment = NSRightTextAlignment
                    
                    nextField.frame = NSMakeRect(10.0, yPos, origin.x - 10.0 - 10.0, 15.0)
                    
                    yLabelArray!.append(nextField)
                    self.addSubview(nextField)
                    
                    yPos -= yOffset
                    kvCurrent -= kvPerTick
                    
                } else {
                    // Fallback on earlier versions
                }
            }
            
            scaleChanged = false
        }
        
        guard let vPoints = voltages
            else
        {
            return
        }
        
        let numDisks = vPoints.count
        NSColor.red.set()
        path.removeAllPoints()
        path.move(to: NSMakePoint(origin.x, origin.y + CGFloat(vPoints[0] / currentScale.y)))
        
        for i in 1..<numDisks
        {
            path.line(to: NSMakePoint(origin.x + CGFloat(i) / CGFloat(currentScale.x), origin.y + CGFloat(vPoints[i] / currentScale.y)))
        }
        
        path.stroke()
    }
    
}
