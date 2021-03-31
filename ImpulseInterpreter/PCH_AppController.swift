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
    let timerRepeatTime = 0.005
    var shotTimeStep = 0
    var nextUpdateTime = 0.0
    let simTimePerStep = 0.1E-6
    
    var coilMenuContents:NSMenu?
    var currentCoilChoice:NSMenuItem?
    
    var stopButton:NSButton?
    var continueButton:NSButton?
    
    var openFileProgress:NSProgressIndicator?
    
    let oscilloWindow = PCH_OscilloscopeView(windowNibName: "PCH_OscilloscopeView")
    
    var simulationIsRunning = false
    
    // ignore everything before this time (to try and get rid of spurious oscillations at the beginning of a simulation)
    let simulationStartTime = -1.0
    
    // The time that will be used for "initial distribution" values
    let initDistributionTime = 1.1E-6
    
    var loadingProgress:NSProgressIndicator?
    
    var modelIsRAW = false
    
    func stopShot()
    {
        if (simulationIsRunning)
        {
            shotTimer.invalidate()
            simulationIsRunning = false
            stopButton!.title = "Reshoot"
            continueButton!.isHidden = false
        }
        else
        {
            // "Reshoot" was clicked, start over
            handleShoot()
        }
    }
    
    func continueShot()
    {
        simulationIsRunning = true
        stopButton!.title = "Stop"
        continueButton!.isHidden = true
        
        shotTimer = Timer.scheduledTimer(timeInterval: timerRepeatTime, target:self, selector: #selector(PCH_AppController.advanceShotTimeStep), userInfo: nil, repeats: true)
    }
    
    @objc func advanceShotTimeStep()
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
            stopButton!.isHidden = true
            continueButton!.isHidden = true
            return
        }
        
        // Ignore everything before the time in simulationStartTime
        if numData.time[shotTimeStep] < simulationStartTime
        {
            shotTimeStep += 1
            return
        }
        
        // advance to the next value we want to display
        while numData.time[shotTimeStep] < nextUpdateTime
        {
            shotTimeStep += 1
        }
        
        nextUpdateTime += simTimePerStep
        
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
        let targetNodes2 = self.currentCoilID() + "I"
        
        guard let numData = numericalData
            else
        {
            return Array()
        }
        
        let nodes = numData.nodeID.filter{$0.contains(targetNodes) || $0.contains(targetNodes2)}.sorted()
        
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
    
    func handleSaveMaxIntersectionVolts()
    {
        guard let numData = numericalData else {
            DLog("numericalData us undefined!")
            return
        }
        
        var outputFileString = String()
        
        let numNodes = numData.nodalVoltages.count
        
        // To access the voltage difference between node X (row) and node Y (col) (with Y > X, and both zero-based), the index is X + Y(Y-1)/2
        
        for X in 0..<numNodes-1
        {
            for Y in (X+1)..<numNodes
            {
                outputFileString.append("\(numData.maxIntersectionVolts[X + Y * (Y-1) / 2])")
                
                if Y < (numNodes - 1)
                {
                    outputFileString.append(",")
                }
            }
            
            outputFileString.append("\n")
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
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
        let targetNodes2 = self.currentCoilID() + "I"
        let nodes = numData.nodeID.filter{$0.contains(targetNodes) || $0.contains(targetNodes2)}
        
        var outputFileString = String()
        
        // we need to remove all the entries where time is less than simulationStartTime
        var firstTimeIndex = 0
        for i in 0..<Int(numData.numTimeSteps)
        {
            if (numData.time[i] >= simulationStartTime)
            {
                firstTimeIndex = i
                break
            }
        }
        
        for nextNode in nodes
        // for var i=0; i<self.numericalData?.diskID.count; i += 1
        {
            guard var vArray = numData.nodalVoltages[nextNode]
                else
            {
                continue
            }
            
            vArray.removeFirst(firstTimeIndex)
            
            var maxV = vArray.max()
            var maxIndex = vArray.firstIndex(of: maxV!)
            
            let minV = vArray.min()
            let minIndex = vArray.firstIndex(of: minV!)
            
            if fabs(minV!) > maxV
            {
                maxV = minV
                maxIndex = minIndex
            }
            
            let nextline = String(format: "%@,%0.7E,%0.7E\n", nextNode, numData.time[maxIndex!], maxV!)
            outputFileString += nextline
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
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
    
    func handleMaxInterdiskV(withSave:Bool)
    {
        guard let numData = numericalData else {
            DLog("numericalData us undefined!")
            return
        }
        
        let targetNodes = self.currentCoilID() + "i"
        let targetNodes2 = self.currentCoilID() + "I"
        let nodes = numData.nodeID.filter{$0.contains(targetNodes) || $0.contains(targetNodes2)}
        
        var outputFileString = String()
        
        var firstTimeIndex = 0
        for i in 0..<Int(numData.numTimeSteps)
        {
            if (numData.time[i] >= simulationStartTime)
            {
                firstTimeIndex = i
                break
            }
        }
        
        for i in 0..<(nodes.count - 2)
        {
            var maxTStep = -1.0
            var maxVdiff = 0.0
            
            for j in firstTimeIndex ..< Int((numData.numTimeSteps))
            {
                let nextV1Array = numData.nodalVoltages[nodes[i]]
                let nextV2Array = numData.nodalVoltages[nodes[i+2]]
                
                let nextV1 = nextV1Array![j]
                let nextV2 = nextV2Array![j]
                
                if (fabs(nextV1 - nextV2) > maxVdiff)
                {
                    maxTStep = (numData.time[j])
                    maxVdiff = fabs(nextV1 - nextV2)
                }
            }
            
            let nextline = String(format: "%@-%@,%0.7E,%0.7E\n", nodes[i], nodes[i+2], maxTStep, maxVdiff)
            outputFileString += nextline
        }
        
        if (withSave)
        {
            let savePanel = NSSavePanel()
            
            savePanel.canCreateDirectories = true
            savePanel.allowedFileTypes = ["txt"]
            
            if (savePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
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
        else
        {
            // must be "show"
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
        let targetNodes2 = self.currentCoilID() + "I"
        let nodes = numData.nodeID.filter{$0.contains(targetNodes) || $0.contains(targetNodes2)}
    
        
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
        
        if (savePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
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
    
    func handleShowWaveforms()
    {
        oscilloWindow.DisplayForCoil(self.currentCoilID(), withNumData: self.numericalData!)
        
        oscilloWindow.showWindow(self)
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
        
        stopButton!.title = "Stop"
        stopButton!.isHidden = false
        continueButton?.isHidden = true
        
        simulationIsRunning = true
        
        gView.isInitDist = false
        gView.minVoltages = nil
        gView.maxVoltages = nil
        gView.voltages = nil
        gView.ZoomAll()
        // gView.needsDisplay = true
        
        shotTimeStep = 0
        nextUpdateTime = 0.0
        shotTimer = Timer.scheduledTimer(timeInterval: timerRepeatTime, target:self, selector: #selector(PCH_AppController.advanceShotTimeStep), userInfo: nil, repeats: true)
        
    }
    
    func handleSaveData()
    {
        guard let numData = self.numericalData else
        {
            DLog("No data!")
            return
        }
        
        let savePanel = NSSavePanel()
        
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["txt"]
        
        if (savePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
        {
            guard let newFileName = savePanel.url else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            // for now we'll just show 1000 points
            let numPointsToSave = 1000
            
            let stepInterval = Int(numData.numTimeSteps) / numPointsToSave
            
            let nodeIDs = numData.nodeID
            
            var fileString = "Time,"
            for nextID in nodeIDs
            {
                fileString += nextID + ","
            }
            
            fileString += "\n"
            
            var i:Int = 0
            while i < numData.numTimeSteps
            {
                fileString += "\(numData.time[i]),"
                
                for nextID in nodeIDs
                {
                    fileString += "\(numData.nodalVoltages[nextID]![i]),"
                }
                
                fileString += "\n"
                
                i += stepInterval
            }
            
            do {
                try fileString.write(to: newFileName, atomically: true, encoding: String.Encoding.utf8)
            }
            catch
            {
                ALog("Could not write file!")
            }
        }
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
        let targetNodes2 = self.currentCoilID() + "I"
        
        guard let numData = numericalData
        else
        {
            return Array()
        }
        
        let nodes = numData.nodeID.filter{$0.contains(targetNodes) || $0.contains(targetNodes2)}
        
        return nodes
    }
    
    /// Function to get the max and min voltages for the currently-selected coil
    func getCoilExtremeVoltages() -> (maxV:Double, minV:Double)
    {
        var maxResult:Double = -Double.greatestFiniteMagnitude
        var minResult:Double = Double.greatestFiniteMagnitude
        
        let targetNodes = self.currentCoilID() + "i"
        let targetNodes2 = self.currentCoilID() + "I"
        
        guard let numData = numericalData
        else
        {
            return (0.0, 0.0)
        }
        
        // we need to remove all the entries where time is less than simulationStartTime
        var firstTimeIndex = 0
        for i in 0..<Int(numData.numTimeSteps)
        {
            if (numData.time[i] >= simulationStartTime)
            {
                firstTimeIndex = i
                break
            }
        }
        
        let nodes = numData.nodeID.filter{$0.contains(targetNodes) || $0.contains(targetNodes2)}
        
        for nextNode in nodes
        {
            guard var vArray = numData.nodalVoltages[nextNode]
            else
            {
                continue
            }
            
            vArray.removeFirst(firstTimeIndex)
            
            let nextMinVal = vArray.min()
            if (nextMinVal < minResult)
            {
                minResult = nextMinVal!
            }
            
            let nextMaxVal = vArray.max()
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
        
        // RAW files always are lowercased, so we need to write this
        if (self.modelIsRAW)
        {
            return currCoil.title.lowercased()
        }
        
        return currCoil.title // .lowercased()
    }
    
    /// Function to extract the numerical data from the file
    func getDataFromFile()
    {
        // progress indicator calls MUST be done on the main queue, so this is the way to do it
        DispatchQueue.main.async {
            self.loadingProgress!.stopAnimation(self)
            
            self.openFileProgress!.isHidden = false
        }
        
        if (currentFileString != nil)
        {
            numericalData = PCH_NumericalData(dataString: currentFileString! as String, openFileProgressIndicator: openFileProgress!)
        }
        else
        {
            ALog("Bad file name!")
            return
        }
        
        self.modelIsRAW = true
        
        // set up the contents of the Coils menu
        let coilNames = numericalData!.getCoilNames()
        
        var gotOne = false
        for nextName in coilNames
        {
            let nextCoilItem = NSMenuItem(title: nextName.uppercased(), action: #selector(AppDelegate.handleCoilChange(_:)), keyEquivalent: "")
            if (!gotOne)
            {
                currentCoilChoice = nextCoilItem
                nextCoilItem.state = .on

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
    
    
    
    /// Function to open an IMPRES file
    func handleOpenImpres() -> Bool
    {
        let getFilePanel = NSOpenPanel()
        
        self.modelIsRAW = false
        
        // set up the panel's properties
        getFilePanel.canChooseDirectories = false
        getFilePanel.canChooseFiles = true
        getFilePanel.allowsMultipleSelection = false
        getFilePanel.allowedFileTypes = ["impres"]
        
        if (getFilePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
        {
            // This is required to be able to open the files created in different programs with the same class.
            NSKeyedUnarchiver.setClass(PCH_BlueBookModelOutput.self, forClassName: "ImpulseResult")
            NSKeyedUnarchiver.setClass(PCH_BB_ModelSection.self, forClassName: "BBSections")
            
            let simResult = NSKeyedUnarchiver.unarchiveObject(withFile: getFilePanel.url!.path) as! PCH_BlueBookModelOutput
            
            let voltMatrix = simResult.voltsArray
            for nextOuter in voltMatrix
            {
                for nextInner in nextOuter
                {
                    if fabs(nextInner) > 1.0E100
                    {
                        DLog("Illegal value!")
                    }
                }
            }
            
            numericalData = PCH_NumericalData(simulationResult: simResult)
            
            // set up the contents of the Coils menu
            let coilNames = numericalData!.getCoilNames()
            
            var gotOne = false
            for nextName in coilNames
            {
                let nextCoilItem = NSMenuItem(title: nextName.uppercased(), action: #selector(AppDelegate.handleCoilChange(_:)), keyEquivalent: "")
                if (!gotOne)
                {
                    currentCoilChoice = nextCoilItem
                    nextCoilItem.state = .on
                    gotOne = true
                }
                
                coilMenuContents!.addItem(nextCoilItem)
            }
            
            guard let grView = graphView
                else
            {
                return true
            }
            
            grView.ZoomAll()
            
            grView.needsDisplay = true
            
            return true
        }
        
        return false
    }
    
    /// Function to open a file using the standard open dialog
    func handleOpenFile() -> Bool
    {
        let getFilePanel = NSOpenPanel()
        
        // set up the panel's properties
        getFilePanel.canChooseDirectories = false
        getFilePanel.canChooseFiles = true
        getFilePanel.allowsMultipleSelection = false
        getFilePanel.allowedFileTypes = ["txt", "raw"]
        
        if (getFilePanel.runModal().rawValue == NSFileHandlingPanelOKButton)
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
                return false
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
                
                return false
            }
            
            DLog("We have a usable file!")
            
            return true
        }
        
        // progress indicator calls MUST be done on the main queue, so this is the way to do it
        DispatchQueue.main.async {
            self.loadingProgress!.stopAnimation(self)
        }
        
        DLog("User selected cancel")
        return false
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
