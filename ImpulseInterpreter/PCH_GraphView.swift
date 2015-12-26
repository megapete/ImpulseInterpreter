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
    let inset = CGFloat(10.0)
    
    /// The app controller object
    weak var theController:PCH_AppController?
    
    /// The current scaling factors of the view
    var currentScale:(x:Double, y:Double) = (1.0, 1.0)
    
    var voltages:[Double]?
    
    /// Function to calculate the scale factors for the graph
    func ZoomAll()
    {
        if (theController!.numericalData == nil)
        {
            return
        }
        
        let xDisks = 1.05 * CGFloat((theController?.numericalData?.diskID.count)!)

        currentScale.x = Double(xDisks / (self.frame.size.width - 3.0 * inset))
        
        let yOverall = 1.05 * CGFloat((theController?.getExtremes().maxV)! - (theController?.getExtremes().minV)!)
        
        currentScale.y = Double(yOverall / (self.frame.size.height - 3.0 * inset))
    }
    
    override func viewDidMoveToSuperview() {
        DLog("We came here")
    }
    
    /// Override of the drawing method
    override func drawRect(dirtyRect: NSRect)
    {
        // required call to super func
        super.drawRect(dirtyRect)

        // Drawing code here.
        // Draw the axes. The Y-axis is always located at the left of the window so we'll start with that.
        NSColor.blackColor().set()
        let path = NSBezierPath()
        path.moveToPoint(NSMakePoint(inset * 1.5, inset / 2.0))
        path.lineToPoint(NSMakePoint(inset * 1.5, self.frame.size.height - inset))
        path.stroke()
        
        let xAxisHeight = 0.0 - CGFloat((theController?.getExtremes().minV)!)
        path.removeAllPoints()
        path.moveToPoint(NSMakePoint(inset / 2.0, inset * 1.5 + xAxisHeight / CGFloat(currentScale.x)))
        path.lineToPoint(NSMakePoint(self.frame.size.width - inset, inset * 1.5 + xAxisHeight / CGFloat(currentScale.x)))
        path.stroke()
        
        let origin:NSPoint = NSMakePoint(inset * 1.5, inset * 1.5 + xAxisHeight / CGFloat(currentScale.x))
        
        guard let vPoints = voltages
        else
        {
            return
        }
        
        let numDisks = vPoints.count
        NSColor.redColor().set()
        path.removeAllPoints()
        path.moveToPoint(NSMakePoint(origin.x, origin.y + CGFloat(vPoints[0] / currentScale.y)))
        
        for i in 1..<numDisks
        {
            path.lineToPoint(NSMakePoint(origin.x + CGFloat(i) / CGFloat(currentScale.x), origin.y + CGFloat(vPoints[i] / currentScale.y)))
        }
        
        path.stroke()
        
    }
    
}
