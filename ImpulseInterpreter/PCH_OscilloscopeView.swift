//
//  PCH_OscilloscopeView.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2016-11-09.
//  Copyright © 2016 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_OscilloscopeView: NSWindowController, NSWindowDelegate
{
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        
        guard let mainView = self.window!.contentView as? OscilloscopeView
            else
        {
            DLog("View is not defined yet!")
            return
        }
        
        mainView.wantsLayer = true
        mainView.layer?.backgroundColor = .black
    }
    
    func windowDidResize(_ notification: Notification)
    {
        guard let mainView = self.window!.contentView as? OscilloscopeView
            else
        {
            return
        }
        
        
        
        mainView.ZoomAll()
        mainView.needsDisplay = true
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
    let inset = CGFloat(50.0)
    
    /// The current scaling factors of the view
    var currentScale:(x:Double, y:Double) = (1.0, 1.0)
    
    var coilID = ""
    var numericalData:PCH_NumericalData? = nil
    
    var numYlabels = 1
    /// An array to hold the subviews that show the yLabels (needed for erasing when changes occur)
    var yLabelArray:[NSTextField]? = nil
    
    var extremes = (maxV:-Double.greatestFiniteMagnitude, minV:Double.greatestFiniteMagnitude)
    
    var scaleChanged = true
    
    var yLabelKvPerTick = 10000.0
    
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
        
        var minTime = numData.time[0]
        var maxTime = numData.time.last!
        currentScale.x = (maxTime - minTime) / Double(self.frame.size.width - 1.25 * inset)
        extremes = (maxV:-Double.greatestFiniteMagnitude, minV:Double.greatestFiniteMagnitude)
        
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
        
        // round up the max extreme to the next 10kV (same for min, but round down)
        yLabelKvPerTick = 10000.0
        
        var yMax = round(extremes.maxV / yLabelKvPerTick + 0.5) * yLabelKvPerTick
        var yMin = round(extremes.minV / yLabelKvPerTick - 0.5) * yLabelKvPerTick
        
        // Set the number of labels so we get one every 10kV
        self.numYlabels = Int((yMax - yMin) / yLabelKvPerTick) + 1
        
        // check if the labels will be too close together and if so, adjust the yLabelKvPerTick property so that there are fewer labels
        while Double(self.frame.size.height - 0.5 * inset) / Double(self.numYlabels - 1) < 25.0
        {
            yLabelKvPerTick += 10000.0
            
            yMax = round(extremes.maxV / yLabelKvPerTick + 0.5) * yLabelKvPerTick
            yMin = round(extremes.minV / yLabelKvPerTick - 0.5) * yLabelKvPerTick
            
            self.numYlabels = Int((yMax - yMin) / yLabelKvPerTick) + 1
        }
        
        let yOverall = /* 1.05 * */ CGFloat(yMax - yMin)
        
        currentScale.y = Double(yOverall / (self.frame.size.height - 0.5 * inset))
        
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
        
        NSColor.white.set()
        let path = NSBezierPath()
        path.move(to: NSMakePoint(inset * 1, inset / 4.0))
        path.line(to: NSMakePoint(inset * 1, self.frame.size.height - inset / 4.0))
        path.stroke()
        
        let yMin = round(extremes.minV / yLabelKvPerTick - 0.5) * yLabelKvPerTick
        let xAxisHeight = -CGFloat(yMin)
        
        path.removeAllPoints()
        path.move(to: NSMakePoint(inset * 0.8 /* / 2.0 */, inset * 0.25 + xAxisHeight / CGFloat(currentScale.y)))
        path.line(to: NSMakePoint(self.frame.size.width - inset * 0.25, inset * 0.25 + xAxisHeight / CGFloat(currentScale.y)))
        path.stroke()
        
        let origin:NSPoint = NSMakePoint(inset * 1, inset * 0.25 + xAxisHeight / CGFloat(currentScale.y))

        if scaleChanged
        {
            if (yLabelArray != nil)
            {
                for nextView in yLabelArray!
                {
                    nextView.removeFromSuperview()
                }
            }
            
            var yPos = self.frame.size.height - inset * 0.25 - 5.0
            let yOffset = (self.frame.size.height - 0.5 * inset) / CGFloat(numYlabels - 1)
            let kvMax = round(extremes.maxV / yLabelKvPerTick + 0.5) * yLabelKvPerTick
            // let kvMin = round(extremes.minV / 50000.0 - 0.5) * 50000.0
            let kvPerTick = yLabelKvPerTick
            var kvCurrent = kvMax
            
            yLabelArray = Array()
            
            for _ in 0..<numYlabels
            {
                if #available(OSX 10.12, *)
                {
                    let theKV = "\(Int(kvCurrent / 1000.0))kV"
                    let nextField = NSTextField(labelWithString: theKV)
                    nextField.isEditable = false
                    nextField.isBezeled = false
                    nextField.isBordered = false
                    nextField.alignment = .right
                    nextField.textColor = NSColor.white
                    
                    nextField.frame = NSMakeRect(5.0, yPos, origin.x - 9.0, 15.0)
                    
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
                
                path.line(to: NSPoint(x: Double(origin.x) + numData.time[i] / currentScale.x, y: Double(origin.y) + voltageToGround / currentScale.y))
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
