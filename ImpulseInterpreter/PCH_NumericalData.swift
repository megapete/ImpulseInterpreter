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
    
    /// An array of strings that holds the "device names" (usually disk names) in the simulation
    var deviceID:[String]
    
    /// A dictionary of arrays where the key is the deviceID and the arrays are the currents through them at each timestep
    var deviceCurrents:[String:[Double]]
    
    /// An array of strings that holds the names of the disks in the file
    var diskID:[String]
    
    /// A 2D array of voltages, where the first index is the time step number and the second index is the disk number that indexes into the diskID property
    var voltage:[[Double]]
    
    /// The maximum voltage in the file (used to scale the output graph)
    var maxVoltage:Double = 0.0
    
    /// The minimum voltage in the file (used to scale the output graph)
    var minVoltage:Double = 0.0
    
    /// The maximum current in the file (used for scaling)
    var maxCurrent:Double = 0.0
    
    /// The minimum current in the file (used for scaling)
    var minCurrent:Double = 0.0
    
    /**
        The designated initializer for the class.
    
        - parameter dataString: The string that holds the entire impulse file
    */
    init?(dataString:String)
    {
        nodeID = Array()
        nodalVoltages = Dictionary()
        
        deviceID = Array()
        deviceCurrents = Dictionary()
        
        diskID = Array()
        time = Array()
        voltage = Array(Array())
        
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
        
        DLog("Number of points: \(points)")
        numTimeSteps = points
        
        // The voltage and current variable names start after the line holding "Variables:"  and go until the line with the string "Values:" in it
        
        while (!nextLine.contains("Variables:"))
        {
            lineCount += 1
            nextLine = linesArray[lineCount]
        }
        
        // We need an array to hold the variable names in the same order as the file
        var varNames:[String] = Array()
        
        while (!nextLine.contains("Values:"))
        {
            if (nextLine.contains("voltage"))
            {
                let voltageLine = nextLine.components(separatedBy: CharacterSet.whitespaces).filter {$0 != ""}
                
                // The variable name is the second component in the string
                varNames.append(voltageLine[1])
                
                // save the node's actual name
                let nodeName = PCH_StrMid(voltageLine[1], start: 2, end: PCH_StrLength(voltageLine[1])-2)
                nodeID.append(nodeName)
                
            }
            else if (nextLine.contains("device_current"))
            {
                let currentLine = nextLine.components(separatedBy: CharacterSet.whitespaces).filter {$0 != ""}
                
                // The variable name is the second component in the string
                varNames.append(currentLine[1])
                
                // save the node's actual name
                let deviceName = PCH_StrMid(currentLine[1], start: 2, end: PCH_StrLength(currentLine[1])-2)
                deviceID.append(deviceName)
            }
            // else ignore the line
            
            lineCount += 1
            nextLine = linesArray[lineCount]
        }
        
        // we're going to want the voltage and current ID arrays sorted, so:
        nodeID.sort()
        deviceID.sort()
        
        
        // bump the line counter past the "Values:" line
        lineCount += 1
        nextLine = linesArray[lineCount]
        
        // reset the max and min values for voltages and currents
        maxCurrent = -DBL_MAX
        maxVoltage = -DBL_MAX
        minCurrent = DBL_MAX
        minVoltage = DBL_MAX
        
        // We now get the data for each timestep
        for i in 0..<points
        {
            if (i % 100 == 0)
            {
                DLog("Processing point: \(i)")
            }
            
            // first line is the timestep index and the time
            let timeStepLine = nextLine.components(separatedBy: CharacterSet.whitespaces).filter {$0 != ""}
            time.append(Double(timeStepLine[1])!)
            
            lineCount += 1
            nextLine = linesArray[lineCount]
            
            for nextVar in varNames
            {
                let varKey = PCH_StrMid(nextVar, start: 2, end: PCH_StrLength(nextVar)-2)
                
                
                guard let value = Double(nextLine.trimmingCharacters(in: CharacterSet.whitespaces))
                else
                {
                    DLog("Illegal value in file")
                    return nil
                }
                
                if (PCH_StrLeft(nextVar, length: 1) == "V")
                {
                    if value > maxVoltage
                    {
                        maxVoltage = value
                    }
                    if value < minVoltage
                    {
                        minVoltage = value
                    }
                    
                    if var vArray = nodalVoltages[varKey]
                    {
                        vArray.append(value)
                        nodalVoltages[varKey] = vArray
                    }
                    else
                    {
                        let vArray = [value]
                        nodalVoltages[varKey] = vArray
                    }
                }
                else if (PCH_StrLeft(nextVar, length: 1) == "I")
                {
                    if value > maxCurrent
                    {
                        maxCurrent = value
                    }
                    if value < minCurrent
                    {
                        minCurrent = value
                    }
                    
                    if var iArray = deviceCurrents[varKey]
                    {
                        iArray.append(value)
                        deviceCurrents[varKey] = iArray
                    }
                    else
                    {
                        let iArray = [value]
                        deviceCurrents[varKey] = iArray
                    }
                }
                
                lineCount += 1
                nextLine = linesArray[lineCount]
            }
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
        Function to return the voltage for a given index into the diskID array at the given timestep
     
        - parameter diskIndex: The index into the diskID array for the required disk
        - parameter timestep: The time step that interests us, must be in the range 0..<numTimeSteps
    */
    func getVoltage(diskIndex:Int, timestep:Int) -> Double
    {
        ZAssert(timestep < Int(numTimeSteps) && timestep >= 0, message: "Illegal timestep")
        ZAssert(diskIndex < diskID.count && diskIndex >= 0, message: "Illegal disk index")
        
        return voltage[timestep][diskIndex]
    }
    
    
    /**
        Function to return the voltage for the given disk ID at the given timestep
     
        - parameter disk: The disk ID in the form "V(XXIYYY)" where YYY is a three-digit integer and XX is the name of the coil
        - parameter timestep: The time step that interests us, must be in the range 0..<numTimeSteps
    */
    func getVoltage(disk:String, timestep:Int) -> Double
    {
        ZAssert(timestep < Int(numTimeSteps) && timestep >= 0, message: "Illegal timestep")
        
        var result:Double = 0.0
        
        if let indexOfDisk = diskID.index(of: disk)
        {
            result = voltage[timestep][indexOfDisk]
        }
        
        return result
    }
    
    
    
    /**
        Function to return the different 2-letter coil names in the file. This assumes that the voltage fields in the file are of the form "V(XXIYYY)" where YYY is a three-digit integer and XX is the name of the coil.
     
        - returns An array of 2-letter strings representing the different coils in the file
    */
    func getCoilNames() -> [String]
    {
        var result = [String]()
        
        let inputIDs = nodeID.filter{$0.contains("i")}
            
        for nextID in inputIDs
        {
            let testString = PCH_StrLeft(nextID, length: 2)
            
            if !result.contains(testString)
            {
                result.append(testString)
            }
            
        }
        
        return result
    }
    
}
