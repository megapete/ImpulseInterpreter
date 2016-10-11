//
//  PCH_AppController.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-21.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class PCH_AppController: NSObject, NSWindowDelegate {
    
    /// The current file as a file handle, URL, and NSString. Any of these fields can be nil if there is no file currently defined (like at program launch).
    var currentFileHandle:FileHandle?
    var currentFileURL:URL?
    var currentFileString:NSString?
    
    var numericalData:PCH_NumericalData?
    
    var graphView:PCH_GraphView?
    var elapsedTimeIndicator:NSTextField?
    
    var shotTimer = Timer()
    var shotTimeStep = 0
    
    var coilMenuContents:NSMenu?
    var currentCoilChoice:NSMenuItem?
    
    // ignore everything before this time (to try and get rid of spurious oscillations at the beginning of a simulation)
    let simulationStartTime = 50.0E-9
    
    // The time that will be used for "initial distribution" values
    let initDistributionTime = 1.2E-6
    
    var loadingProgress:NSProgressIndicator?
    
    func advanceShotTimeStep()
    {
        guard let numData = numericalData
        else
        {
            return
        }
        
        if (shotTimeStep >= Int(numData.numTimeSteps))
        {
            DLog("Done with shot")
            shotTimer.invalidate()
            return
        }
        
        // Ignore everything before the time in simulationStartTime
        if numData.time[shotTimeStep] < simulationStartTime
        {
            shotTimeStep += 1
            return
        }
        
        var elTime = numData.time[shotTimeStep]
        var timeUnits = "µs"
        if (elTime < 100.0E-9)
        {
            timeUnits = "ns"
            elTime *= 1.0E9
        }
        else
        {
            elTime *= 1.0E6
        }
        
        let elTimeDisplay = String(format: "Time elapsed: %0.5f %@", elTime, timeUnits)
        
        elapsedTimeIndicator!.stringValue = elTimeDisplay
        
        guard let grView = graphView
        else
        {
            return
        }
        
        grView.voltages = getCoilNodeVoltagesAt(timeStepIndex: shotTimeStep)
        grView.needsDisplay = true
        shotTimeStep += 1
    }
    
    func getCoilNodeVoltagesAt(timeStepIndex:Int) -> [Double]
    {
        let targetNodes = self.currentCoilID() + "i"
        
        guard let numData = numericalData
            else
        {
            return Array()
        }
        
        let nodes = numData.nodeID.filter{$0.contains(targetNodes)}.sorted()
        
        var result:[Double] = Array()
        
        for nextNode in nodes
        {
            guard let nextVoltageArray = numData.nodalVoltages[nextNode]
            else
            {
                continue
            }
            
            result.append(nextVoltageArray[timeStepIndex])
        }
        
        return result
    }
    
    /** Save the maximum voltages for each "disk" in the data file (as a CSV file). The format of each line of the file is:
        DISKID, TIME_STEP_MAX, MAX_VOLTAGE
    */
    func handleSaveMaxVoltages()
    {
        guard let numData = numericalData else {
            DLog("numericalData us undefined!")
            return
        }
        
        let targetNodes = self.currentCoilID() + "i"
        let nodes = numData.nodeID.filter{$0.contains(targetNodes)}
        
        var outputFileString = String()
        
        for nextNode in nodes
        // for var i=0; i<self.numericalData?.diskID.count; i += 1
        {
            let vArray = numData.nodalVoltages[nextNode]!
            let maxV = vArray.max()
            let maxIndex = vArray.index(of: maxV!)
            
            let nextline = String(format: "%@,%0.7E,%0.7E\n", nextNode, numData.time[maxIndex!], maxV!)
            outputFileString += nextline
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            guard let chosenFile:URL = savePanel.url
            else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            do {
                try outputFileString.write(to: chosenFile, atomically: true, encoding: String.Encoding.utf8)
            }
            catch {
                ALog("Could not write file!")
            }

        }
        
    }
    
    func handleMaxInterdiskV()
    {
        guard let numData = numericalData else {
            DLog("numericalData us undefined!")
            return
        }
        
        let targetNodes = self.currentCoilID() + "i"
        let nodes = numData.nodeID.filter{$0.contains(targetNodes)}
        
        var outputFileString = String()
        
        for i in 0..<(nodes.count - 1)
        {
            var maxTStep = -1.0
            var maxVdiff = 0.0
            
            for j in 0 ..< Int((numData.numTimeSteps))
            {
                let nextV1Array = numData.nodalVoltages[nodes[i]]
                let nextV2Array = numData.nodalVoltages[nodes[i+1]]
                
                let nextV1 = nextV1Array![j]
                let nextV2 = nextV2Array![j]
                
                if (fabs(nextV1 - nextV2) > maxVdiff)
                {
                    maxTStep = (numData.time[j])
                    maxVdiff = fabs(nextV1 - nextV2)
                }
            }
            
            let nextline = String(format: "%@-%@,%0.7E,%0.7E\n", nodes[i], nodes[i+1], maxTStep, maxVdiff)
            outputFileString += nextline
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            guard let chosenFile:URL = savePanel.url
                else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            do {
                try outputFileString.write(to: chosenFile, atomically: true, encoding: String.Encoding.utf8)
            }
            catch {
                ALog("Could not write file!")
            }
            
        }
    }
    
    func handleInitialDistribution(saveValues:Bool)
    {
        // This function outputs the voltage at the recorded time that is closest to initDistributionTime
        guard let numData = numericalData else {
            DLog("numericalData us undefined!")
            return
        }
        
        let targetNodes = self.currentCoilID() + "i"
        let nodes = numData.nodeID.filter{$0.contains(targetNodes)}
    
        
        var initTime = 0
        for i in 0..<Int(numData.numTimeSteps)
        {
            if (numData.time[i] >= initDistributionTime)
            {
                initTime = i
                break
            }
        }
        
        var theTime = numData.time[initTime]
        var timeUnits = "µs"
        if (theTime < 100.0E-9)
        {
            timeUnits = "ns"
            theTime *= 1.0E9
        }
        else
        {
            theTime *= 1.0E6
        }
        
        let elTimeDisplay = String(format: "Initial dist. time: %0.5f %@", theTime, timeUnits)
        
        elapsedTimeIndicator!.stringValue = elTimeDisplay
        
        guard let grView = graphView
            else
        {
            return
        }
        
        grView.voltages = getCoilNodeVoltagesAt(timeStepIndex: initTime)
        grView.maxVoltages = nil
        grView.minVoltages = nil
        grView.isInitDist = true
        grView.needsDisplay = true
        shotTimeStep += 1

        guard (saveValues)
        else
        {
            return
        }
        
        var outputFileString = String(format: "Time: %0.7E\n", (numData.time[initTime]))
        
        for nextNode in nodes
        {
            let vArray = numData.nodalVoltages[nextNode]
            let volts = vArray?[initTime]
            
            outputFileString += String(format: "%@,%0.7E\n", nextNode, volts!)
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            guard let chosenFile:URL = savePanel.url
                else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            do {
                try outputFileString.write(to: chosenFile, atomically: true, encoding: String.Encoding.utf8)
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
        
        gView.isInitDist = false
        gView.minVoltages = nil
        gView.maxVoltages = nil
        gView.ZoomAll()
        
        shotTimeStep = 0
        shotTimer = Timer.scheduledTimer(timeInterval: 0.01, target:self, selector: #selector(PCH_AppController.advanceShotTimeStep), userInfo: nil, repeats: true)
        
    }
    
    /// Override for the awakeFromNib function. We use it to stuff a reference to this controller into the graph view
    override func awakeFromNib()
    {
        // DLog("Setting controller in view!")
        // graphView!.theController = self
    }
    
    /// Delegate function for window resizing
    func windowDidResize(_ notification: Notification)
    {
        // we need to update the scale of the graph view, so we let the view know that
        // graphView!.ZoomAll()
        
    }

    
    /// Function to get an array of the current coil node IDs
    func getCoilNodeIDs() -> [String]
    {
        let targetNodes = self.currentCoilID() + "i"
        
        guard let numData = numericalData
        else
        {
            return Array()
        }
        
        let nodes = numData.nodeID.filter{$0.contains(targetNodes)}
        
        return nodes
    }
    
    /// Function to get the max and min voltages for the currently-selected coil
    func getCoilExtremeVoltages() -> (maxV:Double, minV:Double)
    {
        var maxResult:Double = -DBL_MAX
        var minResult:Double = DBL_MAX
        
        let targetNodes = self.currentCoilID() + "i"
        
        guard let numData = numericalData
        else
        {
            return (0.0, 0.0)
        }
        
        let nodes = numData.nodeID.filter{$0.contains(targetNodes)}
        
        for nextNode in nodes
        {
            let nextMinVal = numData.nodalVoltages[nextNode]!.min()
            if (nextMinVal < minResult)
            {
                minResult = nextMinVal!
            }
            
            let nextMaxVal = numData.nodalVoltages[nextNode]!.max()
            if (nextMaxVal > maxResult)
            {
                maxResult = nextMaxVal!
            }
        }
        
        return (maxResult, minResult)
        
    }
    
    /// Function to get the current coil
    func currentCoilID() -> String
    {
        guard let currCoil = currentCoilChoice
        else
        {
            return ""
        }
        
        return currCoil.title.lowercased()
    }
    
    /// Function to extract the numerical data from the file
    func getDataFromFile()
    {
        if (currentFileString != nil)
        {
            numericalData = PCH_NumericalData(dataString: currentFileString! as String)
        }
        
        // set up the contents of the Coils menu
        let coilNames = numericalData!.getCoilNames()
        
        var gotOne = false
        for nextName in coilNames
        {
            let nextCoilItem = NSMenuItem(title: nextName.uppercased(), action: #selector(AppDelegate.handleCoilChange(_:)), keyEquivalent: "")
            if (!gotOne)
            {
                currentCoilChoice = nextCoilItem
                nextCoilItem.state = NSOnState
                gotOne = true
            }

            coilMenuContents!.addItem(nextCoilItem)
        }
 
        guard let grView = graphView
        else
        {
            return
        }
        
        grView.ZoomAll()
        
        grView.needsDisplay = true
    }
    
    /// Function to open a file using the standard open dialog
    func handleOpenFile()
    {
        let getFilePanel = NSOpenPanel()
        
        // set up the panel's properties
        getFilePanel.canChooseDirectories = false
        getFilePanel.canChooseFiles = true
        getFilePanel.allowsMultipleSelection = false
        getFilePanel.allowedFileTypes = ["txt", "raw"]
        
        if (getFilePanel.runModal() == NSFileHandlingPanelOKButton)
        {
            // we save the old file in case the new file isn't a valid impulse file
            let oldFileHandle = currentFileHandle
            let oldFileURL = currentFileURL
            let oldFileString = currentFileString
            
            let chosenFile:URL = getFilePanel.urls[0]
           
            currentFileURL = chosenFile
            
            guard let chosenFileHandle = try? FileHandle(forReadingFrom: chosenFile)
            else
            {
                DLog("Could not open file for reading")
                return
            }
            
            currentFileHandle = chosenFileHandle
            
            DLog("Name of chosen file is " + chosenFile.path)
            
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
        guard let stringFile = try? NSString(contentsOf: currentFileURL!, encoding: String.Encoding.utf8.rawValue)
        else
        {
            DLog("Couldn't interpret the file as a string")
            return false
        }
        
        // we look for a few required strings 
        let isValid = stringFile.contains("Title") && stringFile.contains("Plotname:") && stringFile.contains("Flags:") && stringFile.contains("No. Variables:") && stringFile.contains("No. Points:")
        
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
