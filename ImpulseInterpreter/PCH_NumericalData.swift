//
//  PCH_NumericalData.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-22.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_NumericalData {

    /// The total number of time steps in the data file
    let numTimeSteps:UInt
    
    /// The time of each voltage measurement
    var time:[Double]
    
    /// An array of strings that holds the names of the disks in the file
    var diskID:[String]
    
    /// A 2D array of voltages, where the first index is the time step number and the second index is the disk number that indexes into the diskID property
    var voltage:[[Double]]
    
    /// The maximum voltage in the file (used to scale the output graph)
    var maxVoltage:Double = 0.0
    
    /// The minimum voltage in the file (used to scale the output graph)
    var minVoltage:Double = 0.0
    
    /**
        The designated initializer for the class.
    
        - parameter dataString: The string that holds the entire impulse file
    */
    init?(dataString:String)
    {
        diskID = Array()
        time = Array()
        voltage = Array(Array())
        
        // The first thing we'll do is split the string into components where each line is a component
        let linesArray = dataString.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        
        // We get at the line (5) that holds the number of time steps
        let numStepsLine = linesArray[5].componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        guard let points = UInt(numStepsLine[2])
        else
        {
            DLog("Cannot read the number of points in the file")
            numTimeSteps = 0
            return nil
        }
        
        DLog("Number of points: \(points)")
        numTimeSteps = points
        
        // The disk voltage names start at line 8 and go until the line with the string "Value:" in it.
        var lineCount = 8
        var nextLine = linesArray[lineCount]
        
        while (!nextLine.containsString("Values:"))
        {
            nextLine = nextLine.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let lineComponents = nextLine.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            diskID.append(lineComponents[1].uppercaseString)
            lineCount++
            nextLine = linesArray[lineCount]
        }
        
        // bump the line counter past the "Values:" line
        lineCount++
        nextLine = linesArray[lineCount]
        let diskCount = diskID.count
        
        var maxVolts = -DBL_MAX
        var minVolts = DBL_MAX
        
        for i:UInt in 0..<points
        {
            if (i % 1000 == 0)
            {
                DLog("Processing: \(i)")
            }
            
            // the first line is special - it holds the point index (which we already have as the value i) and the time of the point.
            nextLine = nextLine.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            let lineComponents = nextLine.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            time.append(Double(lineComponents[1])!)
            lineCount++
            nextLine = linesArray[lineCount]
            
            var innerArray = [Double]()
            for _ in 0..<diskCount
            {
                nextLine = nextLine.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
                
                let nextVoltage = Double(nextLine)!
                
                if (nextVoltage > maxVolts)
                {
                    maxVolts = nextVoltage
                }
                
                if (nextVoltage < minVolts)
                {
                    minVolts = nextVoltage
                }
                
                innerArray.append(nextVoltage)
                
                lineCount++
                nextLine = linesArray[lineCount]
            }
            
            voltage.append(innerArray)
            
            // bump the index past the blank line
            lineCount++
            nextLine = linesArray[lineCount]
        }
        
        maxVoltage = maxVolts
        minVoltage = minVolts
        
    }
    
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
        
        if let indexOfDisk = diskID.indexOf(disk)
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
        
        for nextID in diskID
        {
            // Swift Ranges (and therefore substring extraction) is badly documented. I got this from Stack Overflow
            let testString = nextID[nextID.startIndex.advancedBy(2)...nextID.startIndex.advancedBy(3)].uppercaseString
            
            if !result.contains(testString)
            {
                result.append(testString)
            }
            
        }
        
        return result
    }
    
}
