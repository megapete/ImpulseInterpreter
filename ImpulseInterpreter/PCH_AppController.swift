//
//  PCH_AppController.swift
//  ImpulseInterpreter
//
//  Created by Peter Huber on 2015-12-21.
//  Copyright © 2015 Huberis Technologies. All rights reserved.
//

import Cocoa

class PCH_AppController: NSObject {
    
    /// The current file URL. This field can be nil if there is no file currently defined (like at program launch).
    var currentFile:NSFileHandle?
    
    
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
            let oldFile = currentFile
            
            guard let chosenFile:NSURL = getFilePanel.URLs[0]
            else
            {
                DLog("There is no URL?!?!?")
                return
            }
            
            guard let chosenFileHandle = try? NSFileHandle(forReadingFromURL: chosenFile)
            else
            {
                DLog("Could not open file for reading")
                return
            }
                currentFile = chosenFile
                
                DLog("Name of chosen file is " + currentFile!.path!)
                
                if (!CurrentFileIsValid())
                {
                    // This warning should be an alert instead of a DLog
                    DLog("The chosen file is not a valid impulse file!")
                    
                    currentFile = oldFile
                    return
                }
            }
        }
        
        
    }

    /// Function that does a perfunctory test of the first line of data in currentFile to make sure it is of the correct form
    func CurrentFileIsValid() -> Bool
    {
        if currentFile == nil
        {
            return false
        }
        
        // for now, just return yes
        return true
    }

}
