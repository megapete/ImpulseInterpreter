//
//  PCH_AppController.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-21.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_AppController: NSObject, NSWindowDelegate {
    
    /// The current file as a file handle, URL, and NSString. Any of these fields can be nil if there is no file currently defined (like at program launch).
    var currentFileHandle:NSFileHandle?
    var currentFileURL:NSURL?
    var currentFileString:NSString?
    
    var numericalData:PCH_NumericalData?
    
    var graphView:PCH_GraphView?
    
    var shotTimer = NSTimer()
    var shotTimeStep = 0
    
    func advanceShotTimeStep()
    {
        if (shotTimeStep > Int(numericalData!.numTimeSteps))
        {
            DLog("Done with shot")
            shotTimer.invalidate()
            return
        }
        
        graphView!.voltages = numericalData!.voltage[shotTimeStep]
        graphView!.needsDisplay = true
        shotTimeStep += 100
    }
    
    /** Save the maximum voltages for each "disk" in the data file (as a CSV file). The format of each line of the file is:
        DISKID, TIME_STEP_MAX, MAX_VOLTAGE
    */
    func handleSaveMaxVoltages()
    {
        var outputFileString = String()
        
        for var i=0; i<self.numericalData?.diskID.count; i++
        {
            var maxTStep = -1.0
            var maxV = 0.0
            for var j=0; j<Int((self.numericalData?.numTimeSteps)!); j++
            {
                let nextV = self.numericalData?.getVoltage(diskIndex: i, timestep: j)
                
                if (nextV > maxV)
                {
                    maxTStep = (self.numericalData?.time[j])!
                    maxV = nextV!
                }
            }
            
            let nextline = String(format: "%@,%0.7E,%0.7E\n", (self.numericalData?.diskID[i])!, maxTStep, maxV)
            outputFileString += nextline
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            guard let chosenFile:NSURL = savePanel.URL
            else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            do {
                try outputFileString.writeToURL(chosenFile, atomically: true, encoding: NSUTF8StringEncoding)
            }
            catch {
                ALog("Could not write file!")
            }

        }
        
    }
    
    func handleMaxInterdiskV()
    {
        var outputFileString = String()
        
        for var i=0; i<(self.numericalData?.diskID.count)! - 1; i++
        {
            var maxTStep = -1.0
            var maxVdiff = 0.0
            for var j=0; j<Int((self.numericalData?.numTimeSteps)!); j++
            {
                let nextV1 = self.numericalData?.getVoltage(diskIndex: i, timestep: j)
                let nextV2 = self.numericalData?.getVoltage(diskIndex: i+1, timestep: j)
                
                if (fabs(nextV1! - nextV2!) > maxVdiff)
                {
                    maxTStep = (self.numericalData?.time[j])!
                    maxVdiff = fabs(nextV1! - nextV2!)
                }
            }
            
            let nextline = String(format: "%@-%@,%0.7E,%0.7E\n", (self.numericalData?.diskID[i])!, (self.numericalData?.diskID[i+1])!, maxTStep, maxVdiff)
            outputFileString += nextline
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            guard let chosenFile:NSURL = savePanel.URL
                else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            do {
                try outputFileString.writeToURL(chosenFile, atomically: true, encoding: NSUTF8StringEncoding)
            }
            catch {
                ALog("Could not write file!")
            }
            
        }
    }
    
    func handleInitialDistribution()
    {
        // This function traces the voltage of the first entry in the disk array until it reaches a maximum, and outputs the voltages of that node and all the rest at that timestep
        
        
        var maxV = -1000.0
        var initTime = 0
        for var j=0; j<Int((self.numericalData?.numTimeSteps)!); j++
        {
            let nextV = self.numericalData?.getVoltage(diskIndex: 0, timestep: j)
            
            if (nextV < maxV)
            {
                initTime = j
                break
            }
            else
            {
                maxV = nextV!
            }
        }
        
        var outputFileString = String(format: "Time: %0.7E\n", (self.numericalData?.time[initTime])!)
        
        for var i=0; i<self.numericalData?.diskID.count; i++
        {
            let volts = self.numericalData?.getVoltage(diskIndex: i, timestep: initTime)
            let name = self.numericalData?.diskID[i]
            
            outputFileString += String(format: "%@,%0.7E\n", name!, volts!)
            
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            guard let chosenFile:NSURL = savePanel.URL
                else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            do {
                try outputFileString.writeToURL(chosenFile, atomically: true, encoding: NSUTF8StringEncoding)
            }
            catch {
                ALog("Could not write file!")
            }
            
        }
        
    }
    
    /// Show the impulse shot
    func handleShoot()
    {
        guard let gView = graphView
        else
        {
            DLog("What the fuck?")
            return
        }
        
        gView.ZoomAll()
        
        shotTimeStep = 0
        shotTimer = NSTimer.scheduledTimerWithTimeInterval(0.01, target:self, selector: Selector("advanceShotTimeStep"), userInfo: nil, repeats: true)
        
    }
    
    /// Override for the awakeFromNib function. We use it to stuff a reference to this controller into the graph view
    override func awakeFromNib()
    {
        // DLog("Setting controller in view!")
        // graphView!.theController = self
    }
    
    /// Delegate function for window resizing
    func windowDidResize(notification: NSNotification)
    {
        // we need to update the scale of the graph view, so we let the view know that
        // graphView!.ZoomAll()
        
    }
    
    /// Function to get the maximum and minimum voltages in the current file
    func getExtremes() -> (maxV:Double, minV:Double)
    {
        var maxResult:Double = 0.0
        var minResult:Double = 0.0
        
        if let numData = numericalData
        {
            maxResult = numData.maxVoltage
            minResult = numData.minVoltage
        }
        
        return (maxResult, minResult)
    }
    
    /// Function to extract the numerical data from the file
    func getDataFromFile()
    {
        if (currentFileString != nil)
        {
            numericalData = PCH_NumericalData(dataString: currentFileString! as String)
        }
        
    }
    
    /// Function to open a file using the standard open dialog
    func handleOpenFile()
    {
        let getFilePanel = NSOpenPanel()
        
        // set up the panel's properties
        getFilePanel.canChooseDirectories = false
        getFilePanel.canChooseFiles = true
        getFilePanel.allowsMultipleSelection = false
        getFilePanel.allowedFileTypes = ["txt"]
        
        if (getFilePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            // we save the old file in case the new file isn't a valid impulse file
            let oldFileHandle = currentFileHandle
            let oldFileURL = currentFileURL
            let oldFileString = currentFileString
            
            guard let chosenFile:NSURL = getFilePanel.URLs[0]
            else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            currentFileURL = chosenFile
            
            guard let chosenFileHandle = try? NSFileHandle(forReadingFromURL: chosenFile)
            else
            {
                DLog("Could not open file for reading")
                return
            }
            
            currentFileHandle = chosenFileHandle
            
            DLog("Name of chosen file is " + chosenFile.path!)
            
            // open the file and validate it
            if (!OpenAndValidateFile())
            {
                // This warning should be an alert instead of a DLog
                DLog("The chosen file is not a valid impulse file!")
                
                currentFileHandle = oldFileHandle
                currentFileURL = oldFileURL
                currentFileString = oldFileString
                
                return
            }
            
            
            DLog("We have a usable file!")
            
            // graphView.needsDisplay = true
        }
    }

    /// Function that does a perfunctory test of the first few lines of data in currentFile to make sure it is of the correct form
    func OpenAndValidateFile() -> Bool
    {
        if currentFileHandle == nil
        {
            return false
        }
        
        // Try and load the whole file into a string
        guard let stringFile = try? NSString(contentsOfURL: currentFileURL!, encoding: NSUTF8StringEncoding)
        else
        {
            DLog("Couldn't interpret the file as a string")
            return false
        }
        
        // we look for a few required strings 
        let isValid = stringFile.containsString("Title") && stringFile.containsString("Plotname:") && stringFile.containsString("Flags:") && stringFile.containsString("No. Variables:") && stringFile.containsString("No. Points:")
        
        // That's enough for now - if we have all those, we'll assume that this is a valid file
        if (!isValid)
        {
            return false
        }
        
        currentFileString = stringFile
        
        // for now, just return yes
        return true
    }

}
