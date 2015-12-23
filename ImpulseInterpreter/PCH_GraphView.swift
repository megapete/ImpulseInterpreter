//
//  PCH_GraphView.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-22.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_GraphView: NSView {
    
    /// The app controller object
    weak var theController:PCH_AppController?
    
    /// The current scaling factor of the view
    var currentScale:Double = 1.0
    
    /// Function to calculate the scale factor for the graph
    func ZoomAll()
    {
        
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
}
