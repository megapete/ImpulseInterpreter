//
//  PCH_Defs.swift
//  TransformerModel
//
//  Created by Peter Huber on 2015-07-15.
//  Copyright (c) 2015 Peter Huber. All rights reserved.
//

// Standard defs that should be included in all PCH projects.

import Foundation

/** 

    My standard debug logging function (this will probably change with time)
    
    - parameter message: The debug message
    - parameter file: The name of the file where the debug message was invoked
    - parameter function: The name of the function where the debug message was invoked
    - parameter line: The line number of the file where the debug message was invoked

*/
func DLog(message:String, file:String = __FILE__, function:String = __FUNCTION__, line:Int = __LINE__)
{
    #if DEBUG
        
        print("\(file) : \(function) : \(line) : \(message)\n")
        
    #endif
}

/**

    My standard assertion/debugging logging function (this will probably change with time)

    - parameter message: The debug message
    - parameter file: The name of the file where the debug message was invoked
    - parameter function: The name of the function where the debug message was invoked
    - parameter line: The line number of the file where the debug message was invoked

*/
func ALog(message:String, file:String = __FILE__, function:String = __FUNCTION__, line:Int = __LINE__)
{
    #if DEBUG
    
        let msgString = file + " : " + function + " : " + String(line) + " : " + message
        
        assert(false, msgString)
        
    #else
    
        print("\(file) : \(function) : \(line) : \(message)\n", terminator: "")
        
    #endif
}

/**
    My standard "assert" function
    
    - parameter condition: The condition that must be true to not assert
    - parameter message: The message to show if condition is false
*/
func ZAssert(condition:Bool, message:String)
{
    if !condition
    {
        ALog(message)
    }
}