//
//  PCH_NumericalData.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-22.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

// NOTE: This class assumes that the ".raw" file in question has been created by LTSpice using the "Waveforms" tab with compression set to "None(ASCII files)".

import Cocoa

class PCH_NumericalData /* NSObject , NSCoding */ {

    /// The total number of time steps in the data file
    let numTimeSteps:UInt
    
    /// The time of each voltage measurement
    var time:[Double]
    
    /// An array of strings that holds the nodes in the simulation
    var nodeID:[String]
    
    /// A dictionary of arrays where the key is the nodeID and the arrays are their voltages to ground at each timestep
    var nodalVoltages:[String:[Double]]
    
    /// An array of strings that holds the "device names" (capacitors, inductors, resistors) in the simulation
    var deviceID:[String]
    
    /// A dictionary of arrays where the key is the deviceID and the arrays are the currents through them at each timestep
    var deviceCurrents:[String:[Double]]
    
    /// A matrix holding the maximum voltages that appear between any two sections in the simulation. See PCH_BlueBookModelOutput for the way to access these values
    let maxIntersectionVolts:[Double]
    
    /// The maximum voltage in the file (used to scale the output graph)
    // var maxVoltage:Double = 0.0
    
    /// The minimum voltage in the file (used to scale the output graph)
    // var minVoltage:Double = 0.0
    
    /// The maximum current in the file (used for scaling)
    // var maxCurrent:Double = 0.0
    
    /// The minimum current in the file (used for scaling)
    // var minCurrent:Double = 0.0
    
    /**
        The designated initializer for the class using IMPRES data files (created by ImpulseModeler)
    */
    
    init(simulationResult:PCH_BlueBookModelOutput)
    {
        self.numTimeSteps = UInt(simulationResult.timeArray.count)
        self.time = simulationResult.timeArray
        
        self.nodeID = Array()
        self.deviceID = Array()
        
        for nextSection in simulationResult.sections
        {
            let coilID = String(nextSection.name.prefix(2))
            
            let nextInNode = String(format: "%@I%03d", coilID, nextSection.inNode)
            let nextOutNode = String(format: "%@I%03d", coilID, nextSection.outNode)
            
            // let nextInNode = "\(coilID)I\(nextSection.inNode)"
            // let nextOutNode = "\(coilID)I\(nextSection.outNode)"
            
            if !nodeID.contains(nextInNode)
            {
                nodeID.append(nextInNode)
            }
            
            if !nodeID.contains(nextOutNode)
            {
                nodeID.append(nextOutNode)
            }
            
            deviceID.append(nextSection.name)
            
        }
        
        // self.nodeID = simulationResult.voltageNodes
        // self.deviceID = simulationResult.deviceIDs
        
        self.nodalVoltages = Dictionary()
        for i in 0..<self.nodeID.count
        {
            var vArray:[Double] = Array(repeating: 0.0, count: simulationResult.timeArray.count)
            for j in 0..<simulationResult.timeArray.count
            {
                vArray[j] = (simulationResult.voltsArray[j][i])
                ZAssert(!vArray[j].isNaN, message: "Found a voltage NaN")
            }
            
            self.nodalVoltages[self.nodeID[i]] = vArray
        }
        
        self.deviceCurrents = Dictionary()
        for i in 0..<self.deviceID.count
        {
            var iArray:[Double] = Array(repeating: 0.0, count: simulationResult.timeArray.count)
            for j in 0..<simulationResult.timeArray.count
            {
                iArray[j] = (simulationResult.ampsArray[j][i])
                ZAssert(!iArray[j].isNaN, message: "Found a current NaN")
            }
            
            self.deviceCurrents[self.deviceID[i]] = iArray
        }
        
        self.maxIntersectionVolts = simulationResult.maxVoltDiffArray
    }
    
    /**
        The designated initializer for the class using SPICE RAW data files.
    
        - parameter dataString: The string that holds the entire impulse file
    */
    init?(dataString:String, openFileProgressIndicator:NSProgressIndicator)
    {
        // This field isn't used for SPICE files
        self.maxIntersectionVolts = []
        
        nodeID = Array()
        nodalVoltages = Dictionary()
        
        deviceID = Array()
        deviceCurrents = Dictionary()
        
        // The first thing we'll do is split the string into components where each line is a component
        let linesArray = dataString.components(separatedBy: CharacterSet.newlines)
        
        // Now we'll set up a couple of variables that access the file
        var lineCount = 0
        var nextLine = linesArray[lineCount]
        
        // The first thing we look for is the "No. Points:" field
        while (!nextLine.contains("No. Points:"))
        {
            lineCount += 1
            nextLine = linesArray[lineCount]
        }

        // We get at the line that holds the number of time steps
        let numStepsLine = nextLine.components(separatedBy: CharacterSet.whitespaces).filter{$0 != ""}
        
        guard let points = UInt(numStepsLine[2])
        else
        {
            DLog("Cannot read the number of points in the file")
            numTimeSteps = 0
            return nil
        }
        
        DLog("Number of timesteps: \(points)")
        numTimeSteps = points
        
        time = Array(repeating:0.0, count:Int(numTimeSteps))
        
        // The voltage and current variable names start after the line holding "Variables:"  and go until the line with the string "Values:" in it
        
        while (!nextLine.contains("Variables:"))
        {
            lineCount += 1
            nextLine = linesArray[lineCount]
        }
        
        // We need an array to hold the variable names in the same order as the file
        var varNames:[String] = Array()
        var varKeys:[String] = Array()
        
        DispatchQueue.main.async {
            openFileProgressIndicator.doubleValue = 2.5
            openFileProgressIndicator.displayIfNeeded()
        }
        
        DLog("Reading variable names...")
        while (!nextLine.contains("Values:"))
        {
            if (nextLine.contains("voltage"))
            {
                let voltageLine = nextLine.components(separatedBy: CharacterSet.whitespaces).filter {$0 != ""}
                
                // The variable name is the second component in the string
                varNames.append(voltageLine[1])
                
                // We extract the variable key for use in the nodalVoltage dicitonary and initialize the array for that key
                let midRange = (voltageLine[1].startIndex)...(voltageLine[1].index(voltageLine[1].endIndex, offsetBy: -1))
                // let varKey = PCH_StrMid(voltageLine[1], start: 2, end: PCH_StrLength(voltageLine[1])-2)
                let varKey = String(voltageLine[1][midRange])
                varKeys.append(varKey)
                nodalVoltages[varKey] = Array(repeating:0.0, count:Int(numTimeSteps))
                
                // save the node's actual name
                let nodeName = varKey
                nodeID.append(nodeName)
                
            }
            else if (nextLine.contains("device_current"))
            {
                let currentLine = nextLine.components(separatedBy: CharacterSet.whitespaces).filter {$0 != ""}
                
                // The variable name is the second component in the string
                varNames.append(currentLine[1])
                
                // We extract the variable key for use in the deviceCurrents dicitonary and initialize the array for that key
                let midRange = (currentLine[1].startIndex)...(currentLine[1].index(currentLine[1].endIndex, offsetBy: -1))
                // let varKey = PCH_StrMid(voltageLine[1], start: 2, end: PCH_StrLength(voltageLine[1])-2)
                let varKey = String(currentLine[1][midRange])
                varKeys.append(varKey)
                deviceCurrents[varKey] = Array(repeating:0.0, count:Int(numTimeSteps))
                
                // save the node's actual name
                let deviceName = varKey
                deviceID.append(deviceName)
            }
            // else ignore the line
            
            lineCount += 1
            nextLine = linesArray[lineCount]
        }
        
        DLog("Done")
        
        DispatchQueue.main.async {
            openFileProgressIndicator.doubleValue = 5.0
            openFileProgressIndicator.displayIfNeeded()
        }
        
        // we're going to want the voltage and current ID arrays sorted, so:
        nodeID.sort()
        deviceID.sort()
        
        
        // bump the line counter past the "Values:" line
        lineCount += 1
        nextLine = linesArray[lineCount]
        
        let varNameCount = varNames.count
        
        // reset the max and min values for voltages and currents
        // maxCurrent = -Double.greatestFiniteMagnitude
        // maxVoltage = -Double.greatestFiniteMagnitude
        // minCurrent = Double.greatestFiniteMagnitude
        // minVoltage = Double.greatestFiniteMagnitude
        
        // We now get the data for each timestep
        DLog("Processing values at each timestep")
        for i in 0..<points
        // DispatchQueue.concurrentPerform(iterations: Int(points))
        {
            // (i:Int) -> Void in
            
            if (i != 0) && (i % 100 == 0)
            {
                DLog("Processing timestep: \(i)")
                
                DispatchQueue.main.async {
                    openFileProgressIndicator.increment(by: 10.0)
                    openFileProgressIndicator.displayIfNeeded()
                }
            }
            
            let timeStepIndex = lineCount + (varNameCount + 1) * Int(i)
            let valueIndexBase = timeStepIndex + 1
            
            // first line is the timestep index and the time
            let timeStepLine = linesArray[timeStepIndex].components(separatedBy: CharacterSet.whitespaces).filter {$0 != ""}
            
            time[Int(i)] = Double(timeStepLine[1])!
            
            for j in 0..<varNameCount
            {
                let varKey = varKeys[j]
                let nextVar = varNames[j]
                
                guard let value = Double(linesArray[valueIndexBase + Int(j)].trimmingCharacters(in: CharacterSet.whitespaces))
                else
                {
                    ALog("Illegal value in file")
                    return
                }
                
                if (nextVar.first == "V")
                {
                    nodalVoltages[varKey]![Int(i)] = value
                }
                else if (nextVar.first == "I")
                {
                    deviceCurrents[varKey]![Int(i)] = value
                }
            }
        }
        
        DispatchQueue.main.async {
            openFileProgressIndicator.isHidden = true
            openFileProgressIndicator.doubleValue = 0.0
        }
        
        DLog("Done")
    }
    
    /**
        Required initializer for creating objects from files (NSCoding)

    required init?(coder aDecoder: NSCoder)
    {
        return nil
    }
    */
    
   
    
    /**
        Function to return the different 2-letter coil names in the file. This assumes that the voltage fields in the file are of the form "V(XXIYYY)" where YYY is a three-digit integer and XX is the name of the coil.
     
        - returns An array of 2-letter strings representing the different coils in the file
    */
    func getCoilNames() -> [String]
    {
        var result = [String]()
        
        let inputIDs = nodeID.filter{$0.contains("i") || $0.contains("I")}
            
        for nextID in inputIDs
        {
            let testString = nextID.prefix(2)
            
            if !result.contains(String(testString))
            {
                result.append(String(testString))
            }
            
        }
        
        return result
    }
    
}
