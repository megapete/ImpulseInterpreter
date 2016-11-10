//
//  PCH_OscilloscopeView.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2016-11-09.
//  Copyright © 2016 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_OscilloscopeView: NSWindowController
{
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func DisplayForCoil(_ coilID:String, withNumData:PCH_NumericalData)
    {
        guard let window = self.window
        else
        {
            return
        }
        
        guard let mainView = window.contentView as? OscilloscopeView
        else
        {
            return
        }
        
        mainView.coilID = coilID
        mainView.numericalData = withNumData
        mainView.ZoomAll()
        
        mainView.needsDisplay = true
    }
    
}

class OscilloscopeView:NSView
{
    let inset = CGFloat(20.0)
    
    /// The current scaling factors of the view
    var currentScale:(x:Double, y:Double) = (1.0, 1.0)
    
    var coilID = ""
    var numericalData:PCH_NumericalData? = nil
    
    var numYlabels = 1
    
    var extremes = (maxV:-DBL_MAX, minV:DBL_MAX)
    
    var scaleChanged = true
    
    /// Function to calculate the scale factors for the graph
    func ZoomAll()
    {
        guard let numData = self.numericalData
            else
        {
            return
        }
        
        if coilID == ""
        {
            return
        }
        
        let targetNodeIDs = numData.nodeID.filter{$0.contains(coilID)}
        
        let xNodes = CGFloat(numData.numTimeSteps)
        
        if xNodes == 0.0
        {
            return
        }
        
        currentScale.x = Double((xNodes - 1.0) / (self.frame.size.width - 2.5 * inset))
        
        
        for nextNode in targetNodeIDs
        {
            guard let vArray = numData.nodalVoltages[nextNode]
            else
            {
                continue
            }
            
            let nextMinVal = vArray.min()
            if (nextMinVal! < extremes.minV)
            {
                extremes.minV = nextMinVal!
            }
            
            let nextMaxVal = vArray.max()
            if (nextMaxVal! > extremes.maxV)
            {
                extremes.maxV = nextMaxVal!
            }
        }
        
        // round up the max extreme to the next 25kV (same for min, but round down)
        let yMax = round(extremes.maxV / 25000.0 + 0.5) * 25000.0
        let yMin = round(extremes.minV / 25000.0 - 0.5) * 25000.0
        
        // Set the number of labels so we get one every 20kV
        self.numYlabels = Int((yMax - yMin) / 25000) + 1
        let yOverall = /* 1.05 * */ CGFloat(yMax - yMin)
        
        currentScale.y = Double(yOverall / (self.frame.size.height - 3.0 * inset))
        
        scaleChanged = true
    }
    
    override func draw(_ dirtyRect: NSRect)
    {
        guard let numData = self.numericalData
            else
        {
            return
        }
        
        if coilID == ""
        {
            return
        }
        
        let targetNodeIDs = numData.nodeID.filter{$0.contains(coilID)}
        
        let xNodes = CGFloat(numData.numTimeSteps)
        
        if xNodes == 0.0
        {
            return
        }
        
        NSColor.black.set()
        let path = NSBezierPath()
        path.move(to: NSMakePoint(inset * 1.5, inset / 2.0))
        path.line(to: NSMakePoint(inset * 1.5, self.frame.size.height - inset))
        path.stroke()
        
        let yMin = round(extremes.minV / 25000.0 - 0.5) * 25000.0
        let xAxisHeight = -CGFloat(yMin)
        
        path.removeAllPoints()
        path.move(to: NSMakePoint(inset * 1.3 /* / 2.0 */, inset * 1.5 + xAxisHeight / CGFloat(currentScale.y)))
        path.line(to: NSMakePoint(self.frame.size.width - inset, inset * 1.5 + xAxisHeight / CGFloat(currentScale.y)))
        path.stroke()
        
        let origin:NSPoint = NSMakePoint(inset * 1.5, inset * 1.5 + xAxisHeight / CGFloat(currentScale.y))

        
        var colorHue:CGFloat = 0.0
        
        for nextDisk in targetNodeIDs
        {
            let lineColor = NSColor(calibratedHue: colorHue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            
            lineColor.set()
            
            path.removeAllPoints()
            path.move(to: origin)
            
            for i in 0..<Int(numData.numTimeSteps)
            {
                let voltagesToGround = numData.nodalVoltages[nextDisk]
                let voltageToGround = voltagesToGround![i]
                
                path.line(to: NSPoint(x: Double(origin.x) + Double(i) / currentScale.x, y: Double(origin.y) + voltageToGround / currentScale.y))
            }
            
            path.stroke()
            
            colorHue += 1.0 / 12.0
            
            if colorHue >= 1.0
            {
                colorHue = 0.0
            }
        }
    }
}
