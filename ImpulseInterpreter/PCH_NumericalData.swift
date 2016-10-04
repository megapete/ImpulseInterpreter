//
//  PCH_NumericalData.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-22.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

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
        let linesArray = dataString.components(separatedBy: CharacterSet.newlines)
        
        // We get at the line (5) that holds the number of time steps
        let numStepsLine = linesArray[5].components(separatedBy: CharacterSet.whitespaces)
        
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
        
        while (!nextLine.contains("Values:"))
        {
            nextLine = nextLine.trimmingCharacters(in: CharacterSet.whitespaces)
            let lineComponents = nextLine.components(separatedBy: CharacterSet.whitespaces)
            diskID.append(lineComponents[1].uppercased())
            lineCount += 1
            nextLine = linesArray[lineCount]
        }
        
        // bump the line counter past the "Values:" line
        lineCount += 1
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
            nextLine = nextLine.trimmingCharacters(in: CharacterSet.whitespaces)
            let lineComponents = nextLine.components(separatedBy: CharacterSet.whitespaces)
            time.append(Double(lineComponents[1])!)
            lineCount += 1
            nextLine = linesArray[lineCount]
            
            var innerArray = [Double]()
            for _ in 0..<diskCount
            {
                nextLine = nextLine.trimmingCharacters(in: CharacterSet.whitespaces)
                
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
                
                lineCount += 1
                nextLine = linesArray[lineCount]
            }
            
            voltage.append(innerArray)
            
            // bump the index past the blank line
            lineCount += 1
            nextLine = linesArray[lineCount]
        }
        
        maxVoltage = maxVolts
        minVoltage = minVolts
        
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
        
        for nextID in diskID
        {
            // Swift Ranges (and therefore substring extraction) is badly documented. I got this from Stack Overflow
            let testString = nextID[nextID.characters.index(nextID.startIndex, offsetBy: 2)...nextID.characters.index(nextID.startIndex, offsetBy: 3)].uppercased()
            
            if !result.contains(testString)
            {
                result.append(testString)
            }
            
        }
        
        return result
    }
    
}
