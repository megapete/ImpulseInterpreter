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
    
    /// A 2D array of voltages, where the first index is the time step number and the second index is the disk number (actually, minus 1 compared to the disk number deined in the file)
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
            diskID.append(lineComponents[1])
            lineCount++
            nextLine = linesArray[lineCount]
        }
        
        // bump the line counter past the "Values:" line
        lineCount++
        nextLine = linesArray[lineCount]
        let diskCount = diskID.count
        
        var maxVolts = -DBL_MAX
        var minVolts = DBL_MAX
        
        for _:UInt in 0..<points
        {
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
    
}
